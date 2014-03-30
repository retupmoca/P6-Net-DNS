class Net::DNS::Message;

has Net::DNS::Message::Header $.header;
has Net::DNS::Message::Question @.question;
has Net::DNS::Message::Resource @.answer;
has Net::DNS::Message::Resource @.authority;
has Net::DNS::Message::Resource @.additional;

method Buf {
    return [~] $.header.Buf,
               @.question».Buf,
               @.answer».Buf,
               @.authority».Buf,
               @additional».Buf;
}

method Blob {
    return Blob.new(self.Buf);
}
