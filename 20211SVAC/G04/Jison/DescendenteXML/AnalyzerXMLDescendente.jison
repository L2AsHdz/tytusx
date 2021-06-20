
%lex

ID [A-ZÑa-zñ][A-ZÑa-zñ0-9_-]*

%%
"<!--".*"-->"                    {console.log("Comentario "+yytext);}
([^"<>"]*)/("</"{ID}">")\b      {console.log("texto etiqueta "+yytext);return 'textTag';}
"</"                            {return 'cierreEtiqueta';}
\s+                             //Ignorar espacios
">"                             {return 'greater_than';}
"<"                             {return 'less_than';}
"?"                             {return 'question_mark';}
"="                             {return 'assign';}
"/"                             {return 'slash';}

"xml"                           {return 'xml';}
"version"                       {return 'version';}
"encoding"                      {return 'encoding';}
"\"UTF-8\""                         {return 'utf';}
"\"ASCII\""                         {return 'ascii';}
"\"ISO-8859-1\""                    {return 'iso'}




(["][^"\""]+["])|(['][^']+['])  {return 'value';}
\w+                             {return 'identifier';}

<<EOF>>                         { return 'EOF'; }

.                               {
                                agregarErrorLexico("Lexico",yytext,yylloc.first_line,yylloc.first_column+1);
                                //console.log('     error lexico '+yytext);
                                }


/lex
%{
    let idNodos = 0;
    function getId(){        
        return idNodos++;
    }
    let atributos = [];
    let nodos = [];
%}
%start START

%%

START
    : XML_STRUCTURE EOF     {
        let auxRetorno = new NodoPadre(getId(),"START","-> START","",
                [
                    new NodoPadre(getId(),"XML_STRUCTURE","START -> XML_STRUCTURE EOF","return XML_STRUCTURE.info",$1.hijos),
                    new NodoHijo(getId(),"EOF","","")
                ]
            );            
        return {nodos:$1.nodos,raizCST:auxRetorno};
        }
    | EOF {        
        return {nodos:[new Nodo("",    [],    [], Type.COMMENT,     "",    0,             0)]
            ,raizCST:new NodoPadre(getId(),"XML_STRUCTURE","EOF","",[])
            };
    }
    | error EOF {
        errores.agregarError("Sintactico","error: "+yytext,this._$.first_line,(this._$.first_column+1));
        return {nodos:[new Nodo("",    [],    [], Type.COMMENT,     "",    0,             0)]
            ,raizCST:new NodoPadre(getId(),"START","error EOF","",[])
            };
    }
;

XML_STRUCTURE
    : PROLOG NODES              {
        nodos = [];
        $$ = {nodos:$2.nodos
        ,hijos:[
                new NodoPadre(getId(),"PROLOG","XML_STRUCTURE -> PROLOG NODES","XML_STRUCTURE.info = [PROLOG.valor,NODES.listado]",$1.hijos),
                new NodoPadre(getId(),"NODES","","",$2.hijos)
            ]
        };
        }    
    | error greater_than NODES {
        nodos = [];
        errores.agregarError("Sintactico","error: "+yytext,this._$.first_line,(this._$.first_column+1));
        $$ = {nodos:[new Nodo("",    [],    [], Type.COMMENT,     "",    0,             0)]
            ,hijos:[new NodoPadre(getId(),"XML_STRUCTURE","error sintactico","",[])]
            };
    }
;

PROLOG
    : less_than question_mark xml version assign value encoding assign TYPE_ENCODING question_mark greater_than OPCION_TEXTO_ETIQUETA {
        $$ = {hijos:[
            new NodoHijo(getId(),"<","PROLOG -> &lt;?xml version = value encoding = TYPE_ENCODING ?&gt;","PROLOG.encoding = TYPE_ENCODING.valor"),
            new NodoHijo(getId(),"?","",""),
            new NodoHijo(getId(),"xml","",""),
            new NodoHijo(getId(),"version","",""),
            new NodoHijo(getId(),"=","",""),
            new NodoHijo(getId(),"value","",""),
            new NodoHijo(getId(),"encoding","",""),
            new NodoHijo(getId(),"=","",""),
            new NodoPadre(getId(),"TYPE_ENCODING","","",$9.hijos),
            new NodoHijo(getId(),"?","",""),
            new NodoHijo(getId(),">","",""),
            new NodoPadre(getId(),"OPCION_TEXTO_ETIQUETA","","",$12.hijos),
        ]};
    }
    | less_than question_mark xml encoding assign TYPE_ENCODING version assign value question_mark greater_than OPCION_TEXTO_ETIQUETA {
        $$ = {hijos:[
            new NodoHijo(getId(),"<","PROLOG -> &lt;?xml version = value encoding = TYPE_ENCODING ?&gt;","PROLOG.encoding = TYPE_ENCODING.valor"),
            new NodoHijo(getId(),"?","",""),
            new NodoHijo(getId(),"xml","",""),
            new NodoHijo(getId(),"encoding","",""),
            new NodoHijo(getId(),"=","",""),
            new NodoPadre(getId(),"TYPE_ENCODING","","",$6.hijos),
            new NodoHijo(getId(),"version","",""),
            new NodoHijo(getId(),"=","",""),
            new NodoHijo(getId(),"value","",""),
            new NodoHijo(getId(),"?","",""),
            new NodoHijo(getId(),">","",""),
            new NodoPadre(getId(),"OPCION_TEXTO_ETIQUETA","","",$12.hijos),
        ]};
    }
    | less_than error greater_than  {
        errores.agregarError("Sintactico","error: "+yytext,this._$.first_line,(this._$.first_column+1));
        $$ = {nodos:[new Nodo("",    [],    [], Type.COMMENT,     "",    0,             0)]
            ,hijos:[new NodoPadre(getId(),"PROLOG","error sintactico","",[])]
            };
    }
;

NODES
    : NODE NODES        {
        nodos.unshift($1.nodo);
        $$ = {nodos:nodos
        ,hijos:[
                new NodoPadre(getId(),"NODE","NODES -> NODE NODES","NODES1.agregar(NODE.valor)<br>NODES.listado = NODES1.listado",$1.hijos),
                new NodoPadre(getId(),"NODES","","",$2.hijos)
            ]
        };
        }
    | NODE              {
        nodos.push($1.nodo);
        $$ = {nodos:nodos
            ,hijos:[
                new NodoPadre(getId(),"NODE","NODES -> NODE","NODES.valor = nuevoListado[NODE.valor]",$1.hijos)
            ]
        };
        }
;

NODE
    : OPENING_TAG NODES CLOSING_TAG         {
        nodos = [];
        if($1.identificador === $3.identificador){
            $$ = {nodo:new Nodo($1.identificador, $1.atributos, $2.nodos, Type.DOUBLE_TAG,  $1.textoEtiqueta, @1.first_line, (@1.first_column + 1))
            ,hijos:[
                    new NodoPadre(getId(),"OPENING_TAG","NODE -> OPENING_TAG NODES CLOSING_TAG","NODE.valor = nuevoNodo(NODES.listado)",$1.hijos),
                    new NodoPadre(getId(),"NODES","","",$2.hijos),
                    new NodoPadre(getId(),"CLOSING_TAG","","",$3.hijos)
                ]
            };
        }else{
            errores.agregarError("Semantico","El id de etiqueta no coincide:<br>&lt;"+$1.identificador+"&gt;&lt;/"+$3.identificador+"&gt;",this._$.first_line,(this._$.first_column+1));
            $$ = {nodo:new Nodo("",    [],    [], Type.COMMENT,     "",    0,             0)
                ,hijos:[new NodoPadre(getId(),"NODE","error semantico","",[])]
                };
        }
        
        }
    | OPENING_TAG CLOSING_TAG               {
        if($1.identificador === $2.identificador){
            $$ = {nodo:new Nodo($1.identificador, $1.atributos, [], Type.DOUBLE_TAG,  $1.textoEtiqueta, @1.first_line, (@1.first_column + 1))
            ,hijos:[
                    new NodoPadre(getId(),"OPENING_TAG","NODE -> OPENING_TAG CLOSING_TAG","NODE.valor = nuevoNodo()",$1.hijos),
                    new NodoPadre(getId(),"CLOSING_TAG","","",$2.hijos)
                ]
            };
        }else{
            errores.agregarError("Semantico","El id de etiqueta no coincide:<br>&lt;"+$1.identificador+"&gt;&lt;/"+$2.identificador+"&gt;",this._$.first_line,(this._$.first_column+1));
            $$ = {nodo:new Nodo("",    [],    [], Type.COMMENT,     "",    0,             0)
                ,hijos:[new NodoPadre(getId(),"NODE","error sematico","",[])]
                };
        }
        }
    | EMPTY_TAG                             {
        $$ = {nodo:new Nodo($1.identificador, $1.atributos, [], Type.EMPTY,       $1.textoEtiqueta, @1.first_line, (@1.first_column + 1))
        ,hijos:[
                new NodoPadre(getId(),"EMPTY_TAG","NODE -> EMPTY_TAG","NODE.valor = nuevoNodo()",$1.hijos)
            ]
        };
        }
    | less_than error greater_than  {
        errores.agregarError("Sintactico","error: "+yytext,this._$.first_line,(this._$.first_column+1));
        $$ = {nodo:new Nodo("",    [],    [], Type.COMMENT,     "",    0,             0)
            ,hijos:[new NodoPadre(getId(),"NODE","error sintactico","",[])]
            };
    }
    | OPENING_TAG error CLOSING_TAG EOF {
        errores.agregarError("Sintactico","error: "+yytext,this._$.first_line,(this._$.first_column+1));
        $$ = {nodo:new Nodo("",    [],    [], Type.COMMENT,     "",    0,             0)
            ,hijos:[new NodoPadre(getId(),"NODE","error sintactico","",[])]
            };
    }
;



OPCION_TEXTO_ETIQUETA : textTag        {
        $$ = {contenido: $1,
                hijos:[
                    new NodoPadre(getId(),$1,"OPCION_TEXTO_ETIQUETA -> textTag","OPCION_TEXTO_ETIQUETA.valor = textTag.valorLexico",[])
                ]
            };
        }
    | {
        $$ = {contenido:"",hijos:[new NodoHijo(getId(),"lambda","OPCION_TEXTO_ETIQUETA -> lambda ","")]};
        }
;

OPENING_TAG
    : less_than IDENTIFIER greater_than  OPCION_TEXTO_ETIQUETA            {
        $$={identificador:$2.contenido
            ,textoEtiqueta:$4.contenido
            ,atributos:[]
            ,hijos:[
                new NodoHijo(getId(),"<","OPENING_TAG -> < IDENTIFIER > ","OPENING_TAG.info = [IDENTIFIER.valor, TEXTAG.valor, ATTRIBS.listado]"),
                new NodoPadre(getId(),"IDENTIFIER","","",$2.hijos),
                new NodoHijo(getId(),">","",""),
                new NodoPadre(getId(),"OPCION_TEXTO_ETIQUETA","","",$4.hijos)
            ]
        };

        }
    | less_than IDENTIFIER ATTRIBS greater_than  OPCION_TEXTO_ETIQUETA    {        
        atributos = [];
        $$={identificador:$2.contenido
            ,textoEtiqueta:$5.contenido
            ,atributos:$3.atributos
            ,hijos:[
                new NodoHijo(getId(),"<","OPENING_TAG -> < IDENTIFIER ATRIBS > OPCION_TEXTO_ETIQUETA","OPENING_TAG.info = [IDENTIFIER.valor, TEXTAG.valor, ATTRIBS.listado]"),
                new NodoPadre(getId(),"IDENTIFIER","","",$2.hijos),
                new NodoPadre(getId(),"ATRIBS","","",$3.hijos),
                new NodoHijo(getId(),">","",""),
                new NodoPadre(getId(),"OPCION_TEXTO_ETIQUETA","","",$5.hijos)
            ]
        };
        }
;

CLOSING_TAG
    : cierreEtiqueta IDENTIFIER greater_than    OPCION_TEXTO_ETIQUETA    {
        $$ = {identificador:$2.contenido
                ,hijos:[
                    new NodoHijo(getId(),"<","CLOSING_TAG -> < / IDENTIFIER > OPCION_TEXTO_ETIQUETA","CLOSING_TAG.valor = IDENTIFIER.valor"),
                    new NodoHijo(getId(),"/","",""),
                    new NodoPadre(getId(),"IDENTIFIER","","",$2.hijos),
                    new NodoHijo(getId(),">","","")
            ]
            };
        }
    | error OPENING_TAG {
        errores.agregarError("Sintactico","error: "+yytext,this._$.first_line,(this._$.first_column+1));
        $$ = {nodos:new Nodo("",    [],    [], Type.COMMENT,     "",    0,             0)
            ,hijos:[new NodoPadre(getId(),"CLOSING_TAG","error sintactico","",[])]
            };
    }
;

EMPTY_TAG
    : less_than IDENTIFIER slash greater_than  OPCION_TEXTO_ETIQUETA              {
            $$={identificador:$2.contenido
                ,textoEtiqueta: $5.contenido
                ,atributos:[]
                ,hijos:[
                    new NodoHijo(getId(),"<","EMPTY_TAG -> < IDENTIFIER / > OPCION_TEXTO_ETIQUETA","EMPTY_TAG.info = [IDENTIFIER.valor, TEXTAG.valor, ATTRIBS.listado]"),
                    new NodoPadre(getId(),"IDENTIFIER","","",$2.hijos),
                    new NodoHijo(getId(),"/","",""),
                    new NodoHijo(getId(),">","",""),
                    new NodoPadre(getId(),"OPCION_TEXTO_ETIQUETA","","",$5.hijos)
                ]
            };

            }

    | less_than IDENTIFIER ATTRIBS slash greater_than   OPCION_TEXTO_ETIQUETA     {
        atributos = [];
        $$={identificador:$2.contenido
            ,textoEtiqueta: $6.contenido
            ,atributos: $3.atributos
            ,hijos:[
                    new NodoHijo(getId(),"<","EMPTY_TAG -> < IDENTIFIER ATRIBS / > OPCION_TEXTO_ETIQUETA","EMPTY_TAG.info = [IDENTIFIER.valor, TEXTAG.valor, ATTRIBS.listado]"),
                    new NodoPadre(getId(),"IDENTIFIER","","",$2.hijos),
                    new NodoPadre(getId(),"ATRIBS","","",$3.hijos),
                    new NodoHijo(getId(),"/","",""),
                    new NodoHijo(getId(),">","",""),
                    new NodoPadre(getId(),"OPCION_TEXTO_ETIQUETA","","",$6.hijos)
                ]
        };
        }
;

ATTRIBS
    : ATTRIB ATTRIBS            {
            atributos.unshift($1.atributo);
            $$ = {atributos:atributos
                ,hijos:[
                    new NodoPadre(getId(),"ATRIB","ATRIBS -> ATRIB ATRIBS","ATRIB1.agregar(ATRIB.valor)<br>ATRIBS.listado = ATRIB1.listado",$1.hijos),
                    new NodoPadre(getId(),"ATRIBS","","",$2.hijos)
                ]
            };
            }
    | ATTRIB                    {
        atributos.push($1.atributo);
            $$ = {atributos:atributos, hijos:[ new NodoPadre(getId(),"ATRIB","ATRIBS -> ATRIB","ATRIBS.valor = nuevoListado[ATRIB.valor]",$1.hijos) ] };
        }
;

ATTRIB
    : IDENTIFIER assign value           {
        $$ = {atributo:
            new Atributo($1.contenido,$3.replaceAll('\"', ""), Type.ATRIBUTO, @1.first_line, (@1.first_column + 1))
            ,hijos:[
                new NodoPadre(getId(),"IDENTIFIER","ATRIB -> IDENTIFIER = value","ATRIB.valor=value.lexicoValor",$1.hijos),
                new NodoHijo(getId(),"=","",""),
                new NodoHijo(getId(),"value","","")
            ]
        }
        ;}
;


IDENTIFIER
    : identifier        {$$ = {contenido:$1             ,hijos:[new NodoHijo(getId(),$1,"IDENTIFIER -> identifier","IDENTIFIER.valor = identifier.lexicoValor")]};}
    | xml               {$$ = {contenido:$1             ,hijos:[new NodoHijo(getId(),$1,"IDENTIFIER -> xml"       ,"IDENTIFIER.valor = xml.lexicoValor")]};}
    | version           {$$ = {contenido:$1             ,hijos:[new NodoHijo(getId(),$1,"IDENTIFIER -> version"   ,"IDENTIFIER.valor = version.lexicoValor")]};}
    | encoding          {$$ = {contenido:$1             ,hijos:[new NodoHijo(getId(),$1,"IDENTIFIER -> encoding"  ,"IDENTIFIER.valor = encoding.lexicoValor")]};}
;


TYPE_ENCODING
    : utf               {$$ = {contenido:$1             ,hijos:[new NodoHijo(getId(),$1,"TYPE_ENCODING -> "+$1,"TYPE_ENCODING.valor = uft.lexicoValor")]};}
    | iso               {$$ = {contenido:$1             ,hijos:[new NodoHijo(getId(),$1,"TYPE_ENCODING -> "+$1,"TYPE_ENCODING.valor = iso.lexicoValor")]};}
    | ascii             {$$ = {contenido:$1             ,hijos:[new NodoHijo(getId(),$1,"TYPE_ENCODING -> "+$1,"TYPE_ENCODING.valor = ascii.lexicoValor")]};}
;