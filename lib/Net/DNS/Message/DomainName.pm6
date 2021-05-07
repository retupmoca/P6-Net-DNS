unit role Net::DNS::Message::DomainName;

use experimental :pack;

method parse-domain-name($data is copy, %name-offsets, $start-offset, :$allow-compression = True) {
    my @offset-list = (0);
    my $parsed-bytes = 1;
    my $len = $data.unpack('C');
    $data = Buf.new($data[1..*]);
    my @name;
    while $len > 0 {
        if $len >= 192 {
            die "Compression not allowed here" unless $allow-compression;
            $parsed-bytes += 1;
            @offset-list.push(0);
            @name.append(%name-offsets{$data[0]}.list);
            $data = Buf.new($data[1..*]);
            $len = 0;
        } else {
            $parsed-bytes += $len;
            @offset-list.push($parsed-bytes);
            @name.append(Buf.new($data[0..^$len]).decode('ascii'));
            $data = Buf.new($data[$len..*]);
            $len = $data.unpack('C');
            $parsed-bytes += 1;
            $data = Buf.new($data[1..*]);
        }
    }

    for 1..^+@offset-list {
        my $i = $_ - 1;
        %name-offsets{$start-offset + @offset-list[$i]} = @name[$i..*];
    }
    return (bytes => $parsed-bytes, name => @name).hash;
}
