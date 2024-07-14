// Copyright (c) 2002-2014 JavaMOP Team. All Rights Reserved.
package javamop.parser.ast.visitor;

import javamop.parser.ast.aspectj.ThreadNamePointCut;

/**
 * 
 * Thread name visitor for threadName() pointcut.
 * 
 * */
public class ThreadNameVarVisitor extends BaseStringVisitor {

	public String visit(ThreadNamePointCut p, Object arg){
		String ret = p.getId();
		
		if(ret == null || ret.length() == 0)
			return null;
		return ret;
	}
}
