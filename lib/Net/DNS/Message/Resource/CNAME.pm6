role Net::DNS::Message::Resource::CNAME;

class Net::DNS::CNAME {
    has @.name;

    method Str {
        @.name.join('.');
    }
}

method rdata-parsed {
    my $rdata-length = $.rdata.elems;
    my $name = self.parse-domain-name($.rdata, %.name-offsets, $.start-offset + $.parsed-bytes - $rdata-length);
    return Net::DNS::CNAME.new(:name($name<name>.list));
}
