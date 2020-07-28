#!/usr/bin/perl
#> -----------------------------------------------------------------------------
#> Copyright 2020 Andrew A. V. Murphy All Rights Reserved - github.com/aavmurphy
#> -----------------------------------------------------------------------------
#  no feature qw(indirect);
#  use open qw(:std :utf8);
use utf8;
use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
#> -----------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Simple script to make your .pl, .pm, .cgi scripts Perl 7 Ready
# See github.com/aavmurphy/perl7ready
# --------------------------------------------------------------------------
# Usage: 
#	1. Copy perl7.yaml.example to perl7.yaml and edit it
#
#	2. perl7ready ./dir ./file ./another-dir
#
#	3. Try out on a few scripts first. If something goes wrong, backups are in /tmp,
#		e.g. /dir/file => /tmp/dir/file
#
#	4. You might have to install YAML, sudo cpanm YAML
#
# --------------------------------------------------------------------------

package Perl7ready
	{
	use YAML;
	use IO::All -utf8;
	use File::Spec;

	sub new ( $class )
		{
		my $self =  bless {};

		my $config			= YAML::LoadFile( "perl7.config" );
		$self->{comment_prefix}	= $config->{COMMENT_PREFIX}	|| '';
		$self->{preamble}		= $config->{PREAMBLE}		|| '';
		$self->{pragmas}		= $config->{PRAGMAS}		|| '';

		map { die "no param $_\n" if ! $self->{$_} } qw( comment_prefix preamble pragmas );

		return $self;
		}

	sub read( $self, $file )
		{
		$self->{file}		= File::Spec->rel2abs( $file ); # ../fred.pl => /full/path/fred.pl;
		$self->{perl}		= io( $self->{file} )->slurp;
		$self->{backup}		= $self->{perl};

		#
		warn sprintf( "%6d : %s\n", length $self->{perl}, $file );
		}

	sub remove_comment_prefix( $self )
		{
		# remove any lines starting with comment_prefix
		die "no standard preamble (comment) prefix" if ! $self->{comment_prefix} || ! $self->{comment_prefix} =~ /^#/;

		my $prefix = quotemeta $self->{comment_prefix};

		$self->{perl} =~ s/^ \s* $prefix .*? \n//mxg;
		}

	sub insert_preamble( $self )
		{
		$self->_insert( $self->{preamble} );
		}

	sub insert_pragmas( $self )
		{
		my @pragmas = split /\n/, $self->{pragmas} ;

		# remove old ones
		foreach my $pragma ( @pragmas )
			{
			$pragma =~ s/^\s*\#\s*//;		# remove comment '#', so catches '# use strict' and 'use strict'
			$pragma =~ s/^\s*(use|no)\s*//;	# remove  the 'use' or 'no' from 'use fred', so catched 'use fred' and 'no fred'
			$pragma =~ s/\s*;\s*//;			# remove the ; at the end, so 'use strict', so catches 'use strict ;'
			next if ! $pragma;
			$pragma = quotemeta $pragma;

			$self->{perl} =~ s/^ \s* \#? \s* (use|no) \s* $pragma \s* ; \s*? \n//xmg;
			}

		$self->_insert( $self->{pragmas} );
		}
		
	sub _insert( $self, $insert )
		{
		# insert
		if ( $self->{perl} =~ /^\#!/ )
			{
			my ( $hash_bang, $code ) = split /\n/, $self->{perl}, 2;
			$self->{perl} = "$hash_bang\n$insert$code";
			}
		else
			{
			$self->{perl} = "$insert$self->{perl}";
			}
		}

	sub signatures( $self )
		{
		# FROM
		#	sub create_gpx
		#		{
		#		my ( $self ) = @_;
		#
		# TO
		#	sub create_gpx( $self )
		#		{

		# if you do my $self = shift; my ( $a ) = @_ ; you will have to be cleverer here!

		$self->{perl} =~ s#
			sub \s* ( [\w\d\_]+ ) \s*
				\{ \s*
				my \s* \( \s* ( .*? ) \s* \) \s* = \s* \@_ \s* ; \s*
			#sub $1( $2 )\n\t{\n\t#sgx;
		}

	sub indirect( $self )
	 	{
		# FROM
		#	my $osm = new Cablechip::GPX::Openstreetmap( $self->{gps} ); 
		# TO
		#	my $osm = Cablechip::GPX::Openstreetmap->new( $self->{gps} );

		# and new, not: $new %new @new *new :new _new
		my @code = split /\n/, $self->{perl};

		foreach my $i ( 0 .. $#code )
			{
			next if $code[ $i ] =~ m/#.*?new\s+/; # skip the word new inside a comment
			
			$code[ $i ] =~ s# (?<![$@%_\*\:])new \s+ ( [\w\d\:\_]+ ) \s* #$1->new#xg;
			}

		$self->{perl} = join "\n", @code;
		}

	sub line_feed_eof( $self )
		{
		$self->{perl}	=~ s/\r$//mg;		# when saving as utf8, get lots of spurious ^M, on unix at least (from windows line feeds)
		$self->{perl}	=~ s/(?<!\n)$/\n/;	# make sure \n at eof
		}

	sub backup_save( $self )
		{
		# backup
		my $backup_file = "/tmp/$self->{file}";
		$self->{backup}		> io( $backup_file )->assert;

		# save
		$self->{perl}		> io( $self->{file} );
		}
	}

# --------------------------------------------------------

my ( $dir ) = "@ARGV";

die "usage: $0 /list/of/dirs /and/another/dir\n" if ! $dir;

warn "dirs: $dir\n";

my @files = qx( find $dir -type f -regex '.*\\.\\(pm\\|pl\\|cgi\\)' );

@files = grep !/DAV/, @files;

@files = map { chomp $_; $_ } @files ;

warn "files: ". scalar( @files ) . "\n";

#
my $ready = Perl7ready->new();

foreach my $file ( sort @files )
	{
	$ready->read( $file );
	$ready->signatures;
	$ready->indirect;
	$ready->remove_comment_prefix;
	$ready->insert_pragmas;
	$ready->insert_preamble;
	$ready->line_feed_eof;
	$ready->backup_save;
	}
