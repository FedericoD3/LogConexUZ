var Leido; 
function LeerTexto(URL) {
  var Solicitud = new XMLHttpRequest();
  Solicitud.onreadystatechange = function() {
    if (this.readyState == 4 && this.status == 200) {
      Leido = this.responseText;
    }
  };
  Solicitud.open("GET", URL,false);
  Solicitud.send(); 
  return Leido;
}

function LlenarLista(objLista, URL){
  let Lista = LeerTexto(URL);       //  Leer el contenido del archivo especificado
  var Items = Lista.split('\n');    //  Separar a un array cada linea del archivo
//  Items.sort();
//  Items.reverse();
  for (let i = 0; i < Items.length; i++) {
/* Usando select */
  const Item = document.createElement("option");
  Item.value = i;
  Item.text = Items[i] ;
  objLista.add(Item, null);

/*   Usando datalist    
     objLista.innerHTML += '<option value=' + Items[i] + "></option>";
     objLista.appendChild(opt);
*/
  } 
}