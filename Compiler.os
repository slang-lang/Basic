#!/usr/local/bin/slang

// library imports
import libParam.ParameterHandler;
import System.String;
import System.StringIterator;

// project imports
import Consts;
import CodeEmitter;
import Line;
import Parser;


public int Main( int argc, string args ) modify {
	var debug = false;
	var params = new ParameterHandler( argc, args );

	// Handle parameters
	// {
	if (  params.contains( "debug" )  ) {
		debug = true;
		params.remove( "debug" );
	}

	if (  params.contains( "version" )  ) {
		print( APPNAME + " " + VERSION );
		return 0;
	}

	if (  params.empty()  ) {
		print( "not enought parameters provided!" );
		return -1;
	}
	// }

	try {
		Parser parser = new Parser();

		var emitter = new CodeEmitter( parser.parseFile( params[ 0 ].Key, debug ) );
		return emitter.run( debug );
	}
	catch (  string e  ) {
		print( "Exception: " + e );
	}
	catch (  IException e  ) {
		print( typeid( e ) + ": " + e.what() );
	}
	catch {
		print( "Exception: caught unknown exception!" );
	}

	return -1;
}

