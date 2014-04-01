class Net::DNS::Message::Resource;

has Str @.name is rw;
has Int $.type is rw = 0;
has Int $.class is rw = 0;
has Int $.ttl is rw = 0;
has Buf $.rdata = Buf.new;

has Int $.parsed-bytes;

multi method new($data is copy, %name-offsets is rw, $start-offset){
    my @offset-list = (0);
    my $parsed-bytes = 1;
    my $len = $data.unpack('C');
    $data = Buf.new($data[1..*]);
    my @name;
    while $len > 0 {
        if $len >= 192 {
            @offset-list.push(0);
            @name.push(%name-offsets{$data[0]}.list);
            $data = Buf.new($data[1..*]);
            $len = $data.unpack('C');
            $parsed-bytes += 1;
        } else {
            $parsed-bytes += $len;
            @offset-list.push($len);
            @name.push(Buf.new($data[0..^$len]).decode('ascii'));
            $data = Buf.new($data[$len..*]);
            $len = $data.unpack('C');
            $parsed-bytes += 1;
            $data = Buf.new($data[1..*]);
        }
    }
    my ($type, $class, $ttl, $rdlength) = $data.unpack('nnNn');
    $parsed-bytes += 10;
    $parsed-bytes += $rdlength;
    $data = Buf.new($data[10..*]);
    my $rdata = Buf.new($data[0..^$rdlength]);

    for 1..^+@offset-list {
        my $i = $_ - 1;
        %name-offsets{$start-offset + @offset-list[$i]} = @name[$i..*];
    }

    self.bless(:@name, :$type, :$class, :$ttl, :$rdata :$parsed-bytes);
}

multi method new () {
    self.bless();
}

method Buf {
    my $out = Buf.new;
    for @.qname {
        my $len = pack('C', $_.chars);
        my $str = $_.encode('ascii');
        $out = $out ~ $len ~ $str;
    }
    return $out ~ pack('CnnNn', (0, $.type, $.class, $.ttl, $.rdata.elems)) ~ $.rdata;
}

method Blob {
    Blob.new(self.Buf);
}
