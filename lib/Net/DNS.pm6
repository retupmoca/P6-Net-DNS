use Net::DNS::Message;
use Net::DNS::Type;

class X::Net::DNS is Exception {
    has Net::DNS::Message $.server-message is required;

    method rcode-value() {
        $.server-message.header.rcode;
    }

    method rcode-name() {
        given self.rcode-value {
            when 0 {'NOERROR'}
            when 1 {'FORMERR'}
            when 2 {'SERVFAIL'}
            when 3 {'NXDOMAIN'}
            when 4 {'NOTIMP'}
            when 5 {'REFUSED'}
            when 6 {'YXDOMAIN'}
            when 7 {'XRRSET'}
            when 8 {'NOTAUTH'}
            when 9 {'NOTZONE'}
        }
    }

    method message {
        sprintf('DNS Server responded with: %d (%s)', self.rcode-value, self.rcode-name);
    }
}

class Net::DNS {
    use experimental :pack;

    has $.server;
    has $.socket;
    has $.request-id is rw = 0;

    method new($server, $socket = IO::Socket::INET) {
        self.bless(:$server, :$socket);
    }

    method lookup($type is copy, $host is copy){
        $host ~~ s/\.$//;
        $type = $type.uc;
        my @host = $host.split('.');
        my $message = Net::DNS::Message.new;
        $message.header = Net::DNS::Message::Header.new;
        $message.header.id = (1..65535).pick;
        $message.header.rd = 1;
        $message.header.qdcount = 1;
        my $q = Net::DNS::Message::Question.new;
        $q.qname = @host;
        $q.qtype = Net::DNS::Type.new($type).type;
        $q.qclass = 1;
        $message.question.push($q);

        my $outgoing = $message.Buf;

        my $client = $.socket.new(:host($.server), :port(53));
        $client.write(pack('n', $outgoing.elems) ~ $outgoing);
        my $inc-size = $client.read(2);
        $inc-size = $inc-size.unpack('n');
        my $incoming = $client.read($inc-size);
        if $type eq 'AXFR' {
            my @responses = gather for Net::DNS::Message.new($incoming).answer.list {
                take $_.rdata-parsed;
            };
            unless @responses[0] ~~ Net::DNS::SOA {
                fail "Domain transfer failed.";
            }
            loop {
                if +@responses > 1 && @responses[*-1] ~~ Net::DNS::SOA {
                    return @responses;
                }
                $inc-size = $client.read(2);
                $inc-size = $inc-size.unpack('n');
                $incoming = $client.read($inc-size);
                fail "Domain transfer failed." unless $incoming;
                my $obj = Net::DNS::Message.new($incoming);
                @responses.push(gather for Net::DNS::Message.new($incoming).answer.list { take $_.rdata-parsed; });
            }

            return gather for @responses -> $r {
                for $r.answer.list {
                    take $_.rdata-parsed;
                }
            }
        } else {
            $client.close;

            my $inc-message = Net::DNS::Message.new($incoming);

            X::Net::DNS.new(server-message => $inc-message).fail if $inc-message.header.rcode != 0;

            return gather for $inc-message.answer.list {
                take $_.rdata-parsed;
            }
        }
    }

    method lookup-ips($host, :$inet, :$inet6, :@loopcheck is copy) {
        my @result;

        die "CNAME loop detected" if @loopcheck.grep(* eq $host);
        die "Too many CNAME redirects" if @loopcheck > 10;
        @loopcheck.push: $host;

        if $inet6 || !$inet {
            my @raw = self.lookup('AAAA', $host);
            return @raw[0] if @raw[0] ~~ Failure;

            for @raw.grep(Net::DNS::AAAA) -> $res {
                unless @result.grep({ $_.owner-name eqv $res.owner-name
                        && $_.octets eqv $res.octets }) {
                    @result.append: $res;
                }
            }
            for @raw.grep(Net::DNS::CNAME) -> $res {
                unless @result.grep({ $_.owner-name eqv $res.name}) {
                    @result.append: self.lookup-ips($res.name.join('.'), :$inet, :$inet6, :@loopcheck);
                }
            }
        }

        if $inet || !$inet6 {
            my @raw = self.lookup('A', $host);
            return @raw[0] if @raw[0] ~~ Failure;

            for @raw.grep(Net::DNS::A) -> $res {
                unless @result.grep({ $_.owner-name eqv $res.owner-name
                        && $_.octets eqv $res.octets }) {
                    @result.append: $res;
                }
            }
            for @raw.grep(Net::DNS::CNAME) -> $res {
                unless @result.grep({ $_.owner-name eqv $res.name}) {
                    @result.append: self.lookup-ips($res.name.join('.'), :$inet, :$inet6, :@loopcheck);
                }
            }
        }

        @result;
    }

    method lookup-mx($host, :$inet, :$inet6) {
        my @result;

        my @raw = self.lookup('MX', $host);
        return @raw[0] if @raw[0] ~~ Failure;

        for @raw.grep(Net::DNS::MX).sort(*.priority) -> $res {
            @result.append: self.lookup-ips($res.name.join('.'), :$inet, :$inet6);
        }

        @result;
    }
}
