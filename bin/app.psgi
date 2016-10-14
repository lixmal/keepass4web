#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
 
use KeePass4Web;

KeePass4Web->to_app;
