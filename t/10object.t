#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More tests => 38;
use WWW::Scraper::ISBN;

###########################################################

my $CHECK_DOMAIN = 'www.google.com';

my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

SKIP: {
	skip "Can't see a network connection", 37   if(pingtest($CHECK_DOMAIN));

	$scraper->drivers("OpenLibrary");

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

	$isbn   = "9780861403240";
	$record = $scraper->search($isbn);
    my $error  = $record->error || '';

    SKIP: {
        skip "Website unavailable", 19   if($error =~ /website appears to be unavailable/);

        unless($record->found) {
            diag($record->error);
        } else {
            is($record->found,1);
            is($record->found_in,'OpenLibrary');

            my $book = $record->book;
            is($book->{'isbn'},         '9780861403240'         ,'.. isbn found');
            is($book->{'isbn10'},       '086140324X'            ,'.. isbn10 found');
            is($book->{'isbn13'},       '9780861403240'         ,'.. isbn13 found');
            is($book->{'ean13'},        '9780861403240'         ,'.. ean13 found');
            is($book->{'title'},        'The Colour of Magic (Discworld Novels)'    ,'.. title found');
            is($book->{'author'},       'Terry Pratchett'       ,'.. author found');
            like($book->{'book_link'},  qr|http://openlibrary.org/books/OL8308023M/The_Colour_of_Magic_|);
            is($book->{'image_link'},   'http://covers.openlibrary.org/b/id/652375-L.jpg');
            is($book->{'thumb_link'},   'http://covers.openlibrary.org/b/id/652375-S.jpg');
            is($book->{'publisher'},    'Colin Smythe'          ,'.. publisher found');
            is($book->{'pubdate'},      'October 1989'          ,'.. pubdate found');
            is($book->{'binding'},      'Hardcover'             ,'.. binding found');
            is($book->{'pages'},        '207'                   ,'.. pages found');
            is($book->{'width'},        '139'                   ,'.. width found');
            is($book->{'height'},       '213'                   ,'.. height found');
            is($book->{'weight'},       '379'                   ,'.. weight found');
        }
    }

	$isbn   = "9780552557801";
	$record = $scraper->search($isbn);
    $error  = $record->error || '';

    SKIP: {
        skip "Website unavailable", 19   if($error =~ /website appears to be unavailable/);

        unless($record->found) {
            diag($record->error);
        } else {
            is($record->found,1);
            is($record->found_in,'OpenLibrary');

            my $book = $record->book;
            is($book->{'isbn'},         '9780552557801'         ,'.. isbn found');
            is($book->{'isbn10'},       '0552557803'            ,'.. isbn10 found');
            is($book->{'isbn13'},       '9780552557801'         ,'.. isbn13 found');
            is($book->{'ean13'},        '9780552557801'         ,'.. ean13 found');
            like($book->{'author'},     qr/Terry Pratchett/     ,'.. author found');
            is($book->{'title'},        q|Nation|               ,'.. title found');
            like($book->{'book_link'},  qr|http://openlibrary.org/books/OL24087400M/Nation|);
            is($book->{'image_link'},   'http://covers.openlibrary.org/b/id/6304719-L.jpg');
            is($book->{'thumb_link'},   'http://covers.openlibrary.org/b/id/6304719-S.jpg');
            is($book->{'publisher'},    'Corgi'                 ,'.. publisher found');
            is($book->{'pubdate'},      'September 14, 2009'    ,'.. pubdate found');
            is($book->{'binding'},      'Mass Market Paperback' ,'.. binding found');
            is($book->{'pages'},        300                     ,'.. pages found');
            is($book->{'width'},        109                     ,'.. width found');
            is($book->{'height'},       180                     ,'.. height found');
            is($book->{'weight'},       221                     ,'.. weight found');

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
