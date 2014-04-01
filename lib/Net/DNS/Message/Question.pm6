class Net::DNS::Message::Question;

has Str @.qname is rw;
has Int $.qtype is rw = 0;
has Int $.qclass is rw = 0;

has Int $.parsed-bytes;

multi method new($data is copy, %name-offsets is rw, $start-offset) {
    my @offset-list = (0);
    my $parsed-bytes = 1;
    my $len = $data.unpack('C');
    $data = Buf.new($data[1..*]);
    my @qname;
    while $len > 0 {
        if $len >= 192 {
            @offset-list.push(0);
            @qname.push(%name-offsets{$data[0]}.list);
            $data = Buf.new($data[1..*]);
            $len = $data.unpack('C');
            $parsed-bytes += 1;
        } else {
            $parsed-bytes += $len;
            @offset-list.push($len);
            @qname.push(Buf.new($data[0..^$len]).decode('ascii'));
            $data = Buf.new($data[$len..*]);
            $len = $data.unpack('C');
            $parsed-bytes += 1;
            $data = Buf.new($data[1..*]);
        }
    }
    my ($qtype, $qclass) = $data.unpack('nn');
    $parsed-bytes += 4;

    for 1..^+@offset-list {
        my $i = $_ - 1;
        %name-offsets{$start-offset + @offset-list[$i]} = @qname[$i..*];
    }

    self.bless(:@qname, :$qtype, :$qclass, :$parsed-bytes);
}

multi method new () {
    self.bless();
}

method Buf {
    my $out = Buf.new;
    for @.qname {
        my $len = pack('C', $_.chars);
        my $str = $_.encode('ascii');
        $out = Buf.new($out.list, $len.list, $str.list);
    }
    return Buf.new($out.list, pack('Cnn', (0, $.qtype, $.qclass)).list);
}

method Blob {
    Blob.new(self.Buf);
}
