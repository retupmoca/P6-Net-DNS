class Net::DNS::Message::Resource;

has Str @.name is rw;
has Int $.type is rw = 0;
has Int $.class is rw = 0;
has Int $.ttl is rw = 0;
has Buf $.rdata = Buf.new;

multi method new($data is copy){
    my $len = $data.unpack('C');
    my @name;
    while $len > 0 {
        @name.push(Buf.new($data[1..$len]).decode('ascii'));
        $data = Buf.new($data[$len^..*]);
        $len = $data.unpack('C');
    }
    $data = Buf.new($data[1..*]);
    my ($type, $class, $ttl, $rdlength) = $data.unpack('nnNn');
    $data = Buf.new($data[10..*]);
    my $rdata = Buf.new($data[0..^$rdlength]);
    self.bless(:@name, :$type, :$class, :$ttl, :$rdata);
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
    return Buf.new($out.list, pack('CnnNn', (0, $.type, $.class, $.ttl, $.rdata.elems)).list, $rdata.list);
}

method Blob {
    Blob.new(self.Buf);
}
