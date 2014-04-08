role Net::DNS::Message::Resource::A;

class Net::DNS::A {
    has @.octets;

    method Str {
        @.octets.join('.');
    }
}

method rdata-parsed {
    return Net::DNS::A.new(:octets($.rdata.list));
}
