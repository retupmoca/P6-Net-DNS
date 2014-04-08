role Net::DNS::Message::Resource::NS;

class Net::DNS::NS {
    has @.name;

    method Str {
        @.name.join('.');
    }
}

method rdata-parsed {
    my $name = self.parse-domain-name($.rdata, %.name-offsets, $.start-offset + $.parsed-bytes);
    return Net::DNS::NS.new(:name($name<name>.list));
}
