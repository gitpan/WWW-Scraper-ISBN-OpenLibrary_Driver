#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More tests => 38;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'OpenLibrary';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '9780861403240' => [
        [ 'is',     'isbn',         '9780861403240'     ],
        [ 'is',     'isbn10',       '086140324X'        ],
        [ 'is',     'isbn13',       '9780861403240'     ],
        [ 'is',     'ean13',        '9780861403240'     ],
        [ 'is',     'title',        'The Colour of Magic (Discworld Novels)'    ],
        [ 'is',     'author',       'Terry Pratchett'   ],
        [ 'is',     'publisher',    'Colin Smythe'      ],
        [ 'is',     'pubdate',      'October 1989'      ],
        [ 'is',     'binding',      'Hardcover'         ],
        [ 'is',     'pages',        '207'               ],
        [ 'is',     'width',        '139'               ],
        [ 'is',     'height',       '213'               ],
        [ 'is',     'weight',       '379'               ],
        [ 'is',     'image_link',   'http://covers.openlibrary.org/b/id/652375-L.jpg' ],
        [ 'is',     'thumb_link',   'http://covers.openlibrary.org/b/id/652375-S.jpg' ],
        [ 'like',   'book_link',    qr|http://openlibrary.org/books/OL8308023M/The_Colour_of_Magic_| ]
    ],
    '9780552557801' => [
        [ 'is',     'isbn',         '9780552557801'     ],
        [ 'is',     'isbn10',       '0552557803'        ],
        [ 'is',     'isbn13',       '9780552557801'     ],
        [ 'is',     'ean13',        '9780552557801'     ],
        [ 'is',     'title',        'Nation'            ],
        [ 'is',     'author',       'Terry Pratchett'   ],
        [ 'is',     'publisher',    'Corgi'             ],
        [ 'is',     'pubdate',      'September 14, 2009'],
        [ 'is',     'binding',      'Mass Market Paperback' ],
        [ 'is',     'pages',        300                 ],
        [ 'is',     'width',        109                 ],
        [ 'is',     'height',       180                 ],
        [ 'is',     'weight',       221                 ],
        [ 'is',     'image_link',   'http://covers.openlibrary.org/b/id/6304719-L.jpg' ],
        [ 'is',     'thumb_link',   'http://covers.openlibrary.org/b/id/6304719-S.jpg' ],
        [ 'like',   'book_link',    qr|http://openlibrary.org/books/OL24087400M/Nation| ]
    ],
);

my $tests = 0;
for my $isbn (keys %tests) { $tests += scalar( @{ $tests{$isbn} } ) }


###########################################################

my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

SKIP: {
	skip "Can't see a network connection", $tests+1   if(pingtest($CHECK_DOMAIN));

	$scraper->drivers($DRIVER);

    # this ISBN doesn't exist
	my $isbn = "1234512345";
    my $record;

    eval { $record = $scraper->search($isbn); };
    if($@) {
        like($@,qr/Invalid ISBN specified/);
    }
    elsif($record->found) {
        ok(0,'Unexpectedly found a non-existent book');
    } else {
		like($record->error,qr/Failed to find that book on|website appears to be unavailable/);
    }

    for my $isbn (keys %tests) {
        $record = $scraper->search($isbn);
        my $error  = $record->error || '';

        SKIP: {
            skip "Website unavailable", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /website appears to be unavailable/);

            unless($record->found) {
                diag($record->error);
            }

            is($record->found,1);
            is($record->found_in,$DRIVER);

            my $book = $record->book;
            for my $test (@{ $tests{$isbn} }) {
                if($test->[0] eq 'ok')          { ok(       $book->{$test->[1]},             ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'is')       { is(       $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'isnt')     { isnt(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'like')     { like(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'unlike')   { unlike(   $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); }

            }

            #use Data::Dumper;
            #diag("book=[".Dumper($book)."]");
        }
    }
}

###########################################################

# crude, but it'll hopefully do ;)
sub pingtest {
    my $domain = shift or return 0;
    system("ping -q -c 1 $domain >/dev/null 2>&1");
    my $retcode = $? >> 8;
    # ping returns 1 if unable to connect
    return $retcode;
}
