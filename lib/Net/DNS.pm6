class Net::DNS;

use Net::DNS::Message;

has $.server;
has $.request-id is rw = 0;

method new($server) {
    self.bless(:$server);
}

my %types = A     => 1,
            AAAA  => 28,
            CNAME => 5,
            MX    => 15,
            NS    => 2,
            PTR   => 12,
            SPF   => 99,
            SRV   => 33,
            TXT   => 16;
method lookup($type, $host){
    my @host = $host.split('.');
    my $message = Net::DNS::Message.new;
    $message.header = Net::DNS::Message::Header.new;
    $message.header.id = ++$.request-id;
    $message.header.rd = 1;
    $message.header.qdcount = 1;
    my $q = Net::DNS::Message::Question.new;
    $q.qname = @host;
    $q.qtype = %types{$type};
    $q.qclass = 1;
    $message.question.push($q);

    my $outgoing = $message.Buf;
    
    my $client = IO::Socket::INET.new(:host($.server), :port(53));
    $client.write(pack('n', $outgoing.elems) ~ $outgoing);
    my $inc-size = $client.read(2);
    $inc-size = $inc-size.unpack('n');
    my $incoming = $client.read($inc-size);
    $client.close;

    my $inc-message = Net::DNS::Message.new($incoming);

    return gather for $inc-message.answer.list {
        take $_.rdata-str;
    }
}
