P6-Net-DNS
==========

    my $resolver = Net::DNS.new('8.8.8.8'); # google dns server
    my @addresses = $resolver.lookup('A', 'google.com'); # ("1.2.3.4", "5.6.7.8", ...)

Proper documentation hopefully to follow soonish.
