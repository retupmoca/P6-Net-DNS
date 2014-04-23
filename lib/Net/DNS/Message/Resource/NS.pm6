role Net::DNS::Message::Resource::NS;

class Net::DNS::NS {
    has @.name;

    method Str {
        @.name.join('.');
    }
}

method rdata-parsed {
    my $rdata-length = $.rdata.elems;
    my $name = self.parse-domain-name($.rdata, %.name-offsets, $.start-offset + $.parsed-bytes - $rdata-length);
    return Net::DNS::NS.new(:name($name<name>.list));
}
