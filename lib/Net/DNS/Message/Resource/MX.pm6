role Net::DNS::Message::Resource::MX;

class Net::DNS::MX {
    has $.priority;
    has @.name;

    method Str {
        @.name.join('.');
    }
}

method rdata-parsed {
    my $priority = $.rdata.unpack('n');
    my $name = self.parse-domain-name(Buf.new($.rdata[2..*]),
                                      %.name-offsets,
                                      $.start-offset + $.parsed-bytes);
    return Net::DNS::MX.new(:$priority, :name($name<name>.list));
}
