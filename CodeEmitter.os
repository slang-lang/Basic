
// library imports
import System.Collections.Map;
import System.Collections.Stack;
import System.String;

// project imports
import Line;


public int FIRST_LINE const = 10;

public enum ControlFlow {
	Exit,
	Normal;
}


public object CodeEmitter {
	public void Constructor( Map<int, Line> lines ) {
		assert( lines is Map<int, Line> );

		mCurrentLine = FIRST_LINE;
		mForStack = new Map<string, int>();
		mLines = Map<int, Line> lines;
		mReturnStack = new Stack<int>();
		mVariables = new Map<string, String>();
	}

	public int run(  bool debug = false  ) modify throws {
		if (  !mLines || mLines.empty()  ) {
			throw new Exception( "no valid lines to interpret!" );
		}

		mForStack.clear();
		mReturnStack.clear();
		mVariables.clear();

		if (  debug  ) {
			print( "Started interpreting statements..." );
		}

		writeLine();
		writeLine(  "#include <stdio.h>"  );
		writeLine();
		writeLine(  "int main(  void  )"  );
		writeLine(  "{"  );

		try {
			Line line;

			while (  mCurrentLine > 0  ) {
				print( "LINE: " + mCurrentLine );

				line = mLines.get( mCurrentLine );

				writeLine(  "label_" + line.mLineNumber + ": ;"  );

				mCurrentLine = process( line.mStatement ) ?: line.nextLine();
			}
		}
		catch (  ControlFlow e  ) {
			switch (  e  ) {
				case ControlFlow.Exit: {
					break;
				}
				case ControlFlow.Normal: {
					break;
				}
				default: {
					print(  "Error: " + mCurrentLine  );
					break;
				}
			}
		}

		writeLine();
		writeLine(  "return 0;", 3  );
		writeLine(  "}"  );
		writeLine();

		var file = new System.IO.File(  "output.c", System.IO.File.AccessMode.WriteOnly  );
		file.write(  mOutput  );
		file.close();

		if (  debug  ) {
			print( "Done compiling." );
		}

		return 0;
	}

	protected int process( Statement stmt ) modify throws {
		//print( "process( " + stmt.toString() + " )" );

		switch (  stmt.mStatementType  ) {
			case StatementType.DimStatement: {
				return processDIM(  DimStatement stmt  );
			}
			case StatementType.EndStatement: {
				return processEND(  EndStatement stmt  );
			}
			case StatementType.ForStatement: {
				return processFOR(  ForStatement stmt  );
			}
			case StatementType.GoSubStatement: {
				return processGOSUB(  GotoStatement stmt  );
			}
			case StatementType.GotoStatement: {
				return processGOTO(  GotoStatement stmt  );
			}
			case StatementType.IfStatement: {
				return processIF(  IfStatement stmt  );
			}
			case StatementType.InputStatement: {
				return processINPUT(  InputStatement stmt  );
			}
			case StatementType.LetStatement: {
				return processLET(  LetStatement stmt  );
			}
			case StatementType.NextStatement: {
				return processNEXT(  NextStatement stmt  );
			}
			case StatementType.PrintStatement: {
				return processPRINT(  PrintStatement stmt  );
			}
			case StatementType.RemStatement: {
				return 0;
			}
			case StatementType.ReturnStatement: {
				return processRETURN(  ReturnStatement stmt  );
			}
			default: {
				throw "invalid statement type";
			}
		}

		return 0;
	}

	private void processBinaryExpression(  BinaryExpression exp  ) modify throws {
		print(  "processBinaryExpression(  " + exp.toString() + "  )"  );

		// determine if anyone of the expressions is a string
		bool isStringExp = exp.isString();

		// evaluate left expression
		processExpression(  exp.mLeft  );

		switch (  exp.mOperator  ) {
			// compare operators
			case "=" : { write(  "=="  ); break; }
			case "<" : { write(  "<"  );  break; }
			case "<=": { write(  "<="  ); break; }
			case ">" : { write(  ">"  );  break; }
			case ">=": { write(  ">="  ); break; }
			case "<>": { write(  "!="  ); break; }

			// arithmetic operators
			case "+": { write(  "+"  ); break; }
			case "-": { write(  "-"  ); break; }
			case "*": { write(  "*"  ); break; }
			case "/": { write(  "/"  ); break; }
			case "%": { write(  "%"  ); break; }
			default: { throw "invalid binary operator '" + exp.mOperator + "'!"; }
		}

		processExpression(  exp.mRight  );
	}

	private void processBooleanExpression(  Expression exp  ) modify {
		print(  "processBooleanExpression(  " + exp.toString() + "  )"  );

		processExpression(  exp  );
	}

	private void processConstNumberExpression(  ConstNumberExpression exp  ) modify {
		print(  "processConstNumberExpression(  " + exp.toString() + "  )"  );

		write(  string exp.mValue  );
	}

	private void processConstStringExpression(  ConstStringExpression exp  ) modify {
		print(  "processConstStringExpression(  " + exp.toString() + "  )"  );

		write(  "\"" + exp.mValue + "\""  );
	}

	private void processExpression(  Expression exp  ) modify throws {
		//print(  "processExpression(  " + exp.toString() + "  )"  );

		switch (  true  ) {
			case exp is BinaryExpression: {
				return processBinaryExpression(  BinaryExpression exp  );
			}
			case exp is ConstNumberExpression: {
				return processConstNumberExpression(  ConstNumberExpression exp  );
			}
			case exp is ConstStringExpression: {
				return processConstStringExpression(  ConstStringExpression exp  );
			}
			case exp is VariableExpression: {
				return processVariableExpression(  VariableExpression exp  );
			}
			default: { throw "Unhandled expression found!"; }
		}
	}

	private void processVariableExpression(  VariableExpression exp  ) modify throws {
		print(  "processVariableExpression(  " + exp.toString() + "  )"  );

		write(  exp.mVariable  );
	}

	private int processDIM(  DimStatement stmt  ) modify throws {
		write(  "float " + stmt.mVariable  );
		if (  stmt.mExpression  ) {
			write(  "="  );
			processExpression(  stmt.mExpression  );
		}
		writeLine(  ";"  );

		return stmt.mFollowingStatement ? process(  stmt.mFollowingStatement  ) : 0;
	}

	private int processEND(  EndStatement stmt  ) modify throws {
		if (  stmt.mFollowingStatement  ) {
			throw "END does not support following statements!";
		}

		writeLine(  "return 0;"  );

		return 0;
	}

	private int processFOR(  ForStatement stmt  ) modify throws {
		if (  !mForStack.contains(  stmt.mLoopVariable.mVariable  )  ) {
			mForStack.insert(  stmt.mLoopVariable.mVariable, mCurrentLine  );

			if (  !mVariables.contains( stmt.mLoopVariable.mVariable )  ) {
				mVariables.insert(  stmt.mLoopVariable.mVariable, new String(  "0"  )  );
			}

			processExpression(  stmt.mStartExpression  );
		}
		else {
			processExpression(  stmt.mStepExpression  );
		}

		if (  !processBooleanExpression(  stmt.mTargetExpression  )  ) {
			mForStack.remove(  stmt.mLoopVariable.mVariable  );
		}

		return 0;
	}

	private int processGOSUB( GotoStatement stmt ) modify throws {
		if (  stmt.mFollowingStatement  ) {
			throw "GOTO does not support following statements!";
		}

		var line = mLines.get( mCurrentLine );
		if (  line  ) {
			mReturnStack.push( line.nextLine() );
		}

		return stmt.mLine;
	}

	private int processGOTO(  GotoStatement stmt  ) modify throws {
		if (  stmt.mFollowingStatement  ) {
			throw "GOTO does not support following statements!";
		}

		writeLine(  "goto label_" + stmt.mLine + ";"  );

		return 0;
	}

	private int processIF(  IfStatement stmt  ) modify {
		write(  "if( "  );
		processBooleanExpression(  stmt.mExpression  );
		writeLine(  " )"  );
		writeLine(  "{"  );
		process(  stmt.mThenBlock  );
		writeLine(  "}"  );

		return stmt.mFollowingStatement ? process(  stmt.mFollowingStatement  ) : 0;
	}

	private int processINPUT(  InputStatement stmt  ) modify throws {
		/*
		if (  !mVariables.contains(  stmt.mVariable  )  ) {
			throw new Exception(  "Unknown variable '" + stmt.mVariable + "' referenced!"  );
		}
		*/

		writeLine(  "scanf( \"%f\",&" + stmt.mVariable + " );"  );

		return stmt.mFollowingStatement ? process(  stmt.mFollowingStatement  ) : 0;
	}

	private int processLET(  LetStatement stmt  ) modify throws {
		write(  stmt.mVariable + " = "  );
		processExpression(  stmt.mExpression  );
		writeLine(  ";"  );

		return stmt.mFollowingStatement ? process(  stmt.mFollowingStatement  ) : 0;
	}

	private int processNEXT( NextStatement stmt ) modify throws {
		if (  mForStack.contains(  stmt.mLoopVariable  )  ) {
			return mForStack.get(  stmt.mLoopVariable  );
		}

		return 0;
	}

	private int processPRINT(  PrintStatement stmt  ) modify {
		write(  "printf( \"%s\\n\","  );
		processExpression(  stmt.mExpression  );
		writeLine(  " );"  );

		return stmt.mFollowingStatement ? process(  stmt.mFollowingStatement  ) : 0;
	}

	private int processRETURN(  ReturnStatement stmt  ) modify {
		assert(  !"RETURN not supported"  );

		return -1;
	}

	//////////////////////////////////////////////////////

	private void write(  string line  ) modify {
		mOutput += line;
	}

	private void writeLine(  string line = "", int indentation = 0  ) modify {
		mOutput += strlpad(  line + LINEBREAK, indentation, " "  );
	}

	//////////////////////////////////////////////////////

	protected int mCurrentLine;
	protected Map<string, int> mForStack;
	protected int mIndentation = 3;
	protected Map<int, Line> mLines;
	protected string mOutput;
	protected Stack<int> mReturnStack;
	protected Map<string, String> mVariables;
}

