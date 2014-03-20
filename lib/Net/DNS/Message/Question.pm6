class Net::DNS::Message::Question;

has Str @.qname is rw;
has Int $.qtype is rw = 0;
has Int $.qclass is rw = 0;

multi method new($data is copy) {
    my $len = $data.unpack('C');
    my @qname;
    while $len > 0 {
        @qname.push(Buf.new($data[1..$len]).decode('ascii'));
        $data = Buf.new($data[$len^..*]);
        $len = $data.unpack('C');
    }
    $data = Buf.new($data[1..*]);
    my ($qtype, $qclass) = $data.unpack('nn');
    self.bless(:@qname, :$qtype, :$qclass);
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
