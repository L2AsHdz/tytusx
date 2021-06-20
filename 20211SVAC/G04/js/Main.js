let raizCST;
let errores = new Errores();
function analizar() {
    const texto = document.getElementById('inputXML');
    const consola = document.getElementById('result');
    errores = new Errores();
    let auxResultado;
    try {
        // @ts-ignore
        auxResultado = AnalyzerXMLDescendente.parse(texto.value);
        console.log(auxResultado);
    }
    catch (err) {
        console.log(err);
        errores.agregarError("Irrecuperable", "Error irecuperable (Posiblmente no cerro alguna etiqueta)", 0, 0);
        auxResultado = { nodos: [new Nodo("", [], [], Type.COMMENT, "", 0, 0)],
            raizCST: new NodoPadre(0, "error", "Error sin recuperacion", "", [])
        };
    }
    let nodos = auxResultado.nodos;
    let entornoGlobal = new Entorno(null);
    addSimbolosToEntorno(entornoGlobal, nodos, "global");
    setSymbolTable(entornoGlobal);
    raizCST = auxResultado.raizCST;
    if (errores.getErrores().length > 0) {
        errores.agregarEncabezado("XML");
    }
    analizarXpath(entornoGlobal);
}
function addSimbolosToEntorno(anterior, nodos, ambito) {
    nodos.forEach((nodo) => {
        if (nodo.getType() != Type.COMMENT) {
            let entornoNode = new Entorno(anterior);
            nodo.getAtributos().forEach((attr) => {
                attr.setAmbito(nodo.getNombre());
                entornoNode.add(attr);
            });
            if (nodo.getNodos().length > 0) {
                addSimbolosToEntorno(entornoNode, nodo.getNodos(), nodo.getNombre());
            }
            nodo.setAmbito(ambito);
            nodo.setEntorno(entornoNode);
            anterior.add(nodo);
        }
    });
}
