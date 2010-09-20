#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Gtk2::Ex::HyperTextView' );
}

diag( "Testing Gtk2::Ex::HyperTextView $Gtk2::Ex::HyperTextView::VERSION, Perl $], $^X" );
