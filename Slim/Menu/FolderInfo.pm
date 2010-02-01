package Slim::Menu::FolderInfo;

# Squeezebox Server Copyright 2001-2009 Logitech.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2.

# Provides OPML-based extensible menu for folder info

=head1 NAME

Slim::Menu::FolderInfo

=head1 DESCRIPTION

Provides a dynamic OPML-based folder info menu to all UIs and allows
plugins to register additional menu items.

=cut

use strict;

use base qw(Slim::Menu::Base);

use Scalar::Util qw(blessed);

use Slim::Utils::Log;
use Slim::Utils::Strings qw(cstring);

sub init {
	my $class = shift;
	$class->SUPER::init();
	
	Slim::Control::Request::addDispatch(
		[ 'folderinfo', 'items', '_index', '_quantity' ],
		[ 1, 1, 1, \&cliQuery ]
	);
}

sub name {
	return 'FOLDER_INFO';
}

##
# Register all the information providers that we provide.
# This order is defined at http://wiki.slimdevices.com/index.php/UserInterfaceHierarchy
#
sub registerDefaultInfoProviders {
	my $class = shift;
	
	$class->SUPER::registerDefaultInfoProviders();

	$class->registerInfoProvider( addFolder => (
		menuMode  => 1,
		after    => 'top',
		func      => \&addFolderEnd,
	) );

	$class->registerInfoProvider( addFolderNext => (
		menuMode  => 1,
		after    => 'addFolder',
		func      => \&addFolderNext,
	) );

	$class->registerInfoProvider( playItem => (
		menuMode  => 1,
		after    => 'addFolderNext',
		func      => \&playFolder,
	) );


}

sub addFolderNext {
	my ( $client, $tags ) = @_;
	addFolder( $client, $tags, 'insert', cstring($client, 'PLAY_NEXT') );
}

sub addFolderEnd {
	my ( $client, $tags ) = @_;
	addFolder( $client, $tags, 'add', cstring($client, 'ADD_TO_END') );
}

sub addFolder {
	my ($client, $tags, $cmd, $label) = @_;

	my $actions = {
		go => {
			player => 0,
			cmd => [ 'playlistcontrol' ],
			params => {
				folder_id => $tags->{folder_id},
				cmd => $cmd,
			},
			nextWindow => 'parent',
		},
	};
	$actions->{play} = $actions->{go};
	$actions->{add}  = $actions->{go};

	return [ {
		type => 'text',
		name => $label,
		jive => {
			actions => $actions
		}, 
	} ];
}


sub playFolder {
	my ( $client, $tags) = @_;

	my $actions = {
		go => {
			player => 0,
			cmd => [ 'playlistcontrol' ],
			params => {
				folder_id => $tags->{folder_id},
				cmd => 'load',
			},
			nextWindow => 'parent',
		},
	};
	$actions->{play} = $actions->{go};
	$actions->{add}  = $actions->{go};

	return [ {
		type => 'text',
		name => cstring($client, 'PLAY'),
		jive => {
			actions => $actions
		}, 
	} ];
}


sub cliQuery {
	my $request = shift;
	
	my $client    = $request->client;
	my $folder_id = $request->getParam('folder_id');
	my $menuMode  = $request->getParam('menu') || 0;

	unless ( $folder_id ) {
		$request->setStatusBadParams();
		return;
	}

	my $tags = {
		folder_id => $folder_id,
		menuMode  => $menuMode,
	};
	
	my $feed = Slim::Menu::FolderInfo->menu( $client, $tags );
	
	Slim::Control::XMLBrowser::cliQuery( 'folderinfo', $feed, $request );
}

1;