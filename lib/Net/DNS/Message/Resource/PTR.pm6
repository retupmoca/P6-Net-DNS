role Net::DNS::Message::Resource::PTR;

class Net::DNS::PTR {
    has @.name;

    method Str {
        @.name.join('.');
    }
}

method rdata-parsed {
    my $name = self.parse-domain-name($.rdata, %.name-offsets, $.start-offset + $.parsed-bytes);
    return Net::DNS::PTR.new(:name($name<name>.list));
}
