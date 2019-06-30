package GoC::Event;

use strict;
use warnings;

use Class::Accessor::Lite(
    new => 1,
    rw  => [
    'id', 
    'name', 
    'date',
    'queen',  # name, email, whatever, not a FK
#        'email', 
#        'xx', 
    ],
);

__DATA__
CREATE TABLE event (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(255),
    date TEXT(20),
    status VARCHAR(255)
);
