Quipu
=====

Un sistema de control de gestión para pequeñas empresas, basado en la 
contabilidad.

###Acerca del nombre

*Quipu* es un sistema de registro estadístico y contable utilizado por los 
Incas antes de la llegada de los españoles. Consiste en un grupo de cuerdas de
colores --cada una con distinta cantidad de nudos-- que están amarradas a una
cuerda principal. 

Por cierto se trata de un sistema algo más antiguo que la *partida 
doble* desarrollada por Luca Paccioli, en la misma época en que Cristobal
Colón llegaba al llamado 'Nuevo Continente'. La palabra *quipu* significa 
*nudo* en quechua. Visitar el siguiente [sitio][ref] para más información. 
También se suele escribir *Kipu*.


   [ref]: http://incas.perucultural.org.pe/histec2.htm


##Descripción

Este programa está basado en las condiciones legales existentes en Chile,
en especial respecto de las normas tributarias. Pero su propósito explícito
es ir más allá y usar la contabilidad como una efectiva herramienta de 
control.

Se trata de aprovechar el obligado registro de la documentación
mercantil (facturas, boletas, notas de débito y crédito) para procesar
información necesaria en el control de las gestión de la pequeñas
empresas.


##Requisitos

+ Perl 5.8 o superior
+ Tk804
+ Módulos Perl 
  - DBD::SQLite
  - Tk::TableMatrix
  - Tk::BrowseEntry
  - Date::Simple
  - Number::Format
  - PDF::API2
+ Cualquier sistema operativo que soporte lo anterior.


##Instalación, configuracion y uso

### Requerimientos previos

+ Tener instalados todos los programas definidos como *Requisitos*
+ Disponer del programa *git*. En el sitio [github][] están disponibles
guías sobre cómo instalarlo en los distintos sistemas operativos.


   [github]: http://github.com/guides/home


### Descargar el programa

Ejecutar el siguiente comando, desde un terminal o consola: 

	git clone git://gihub.com/varaya/Quipu.git
	
De esta manera se baja el programa y se crea el directorio *Quipu*, dentro
del directorio en donde se ejecutó el programa. Para seguir con el proceso, 
ejecutar 

	cd Quipu


### Verificar los requisitos

Luego de haber cambiado de directorio, ejecutar el comando

	perl modulos.pl
	
Esto permitirá verificar que estén instalados todos los módulos Perl que
necesita el programa Quipu. Se falta alguno, deberá ser instalado antes 
de seguir con la configuración. Se puede usar el programa `cpan` o alguna
interfaz gráfica disponible en el sistema operativo.

### Configuración inicial

Para usar el programa es necesario crear una empresa y definir un plan de
cuentas. Esto se realiza en dos etapas:

Primero, con el comando Linux

	./configurar.pl &

se accede a una interfaz gráfica para registrar datos básicos (año inicial,
tasa del IVA) y crear la empresa, indicado RUT (en formato de números sin
punto, guión y dígito verificador) y nombre.

Segundo, con el comando 

	./central.pl &
	
se entra la programa principal para completar la configuración inicial,
mediante la siguientes acciones:

1. Completar los datos de la empresa: opción de menú **Registra - Empresa**.

2. Crear el plan de cuentas, que se compone de cuentas y subgrupos de cuentas. 
Están predefinidos los grandes grupos (Activo, Pasivo, Ingresos y Gastos) y
un conjunto mínimo de subgrupos. Como absoluto mínimo deben existir las 
siguientes cuentas (se indica el subgrupo; los nombre son indicativos):

	> + Caja (10)
	> + Clientes (11)
	> + IVA Crédito Fiscal (11)
	> + Proveedores (20)
	> + IVA Débito Fiscal (20)
	> + Capital (22)
	> + Resultado del Ejercicio (22)
	> + Ingresos por venta (30)
	> + Costos de ventas (40)

3. Registrar los datos de las cuentas a las que se imputa el monto total
y el IVA, tanto para las facturas de compra como de venta: opción de 
menú **Registra - Documento**. Esto facilita la contabilización de dichos 
documentos.

### Uso del programa

El programa se inicia con el comando:

	./central.pl &

Se puede crear un icono en el escritorio, siguiendo los procedimientos 
usuales del sistema operativo correspondiente.

Para agregar nuevas empresas, se usa el comando 

	./configurar.pl &
	
y se completan sus datos desde la opción **Registra - Empresa** en el
programa `central.pl`.

### Actualización

Las actualizaciones del programa se obtienen desde Internet ejecutando 
el comando

	git pull
	
en el directorio *Quipu*.


##Licencia

###Declaración de Principios

Este programa informático no es una mercancía: es libre y gratuito. Por 
tratarse de un programa de código abierto, puede ser modificado, utilizado 
y distribuido en las condiciones, mínimamente restrictivas, definidas en 
esta Licencia.

Los intercambios que pueda generar, quedan sujetos a los principios de 
reciprocidad y retribución del trabajo efectivamente realizado. Por ello,
este programa *no* está sujeto a una transacción mercantil.


###Condiciones de Uso y Distribución

Está permitido:

1. Hacer y entregar copias de este programa sin restricción,
   con la obligación de incluir el presente documento y 
   traspasar a terceros los derechos previstos en esta
   Licencia.

2. Realizar modificaciones al programa, dejando constancia en 
   los archivos respectivos quién, cómo y cuándo realizó la
   modificación, con la obligación de cumplir alguna de las 
   siguientes condiciones:

	>  a. Dejar las modificaciones libremente disponibles a otros usuarios, enviándolas al autor del programa original.
      
	>  b. Utilizarlas exclusivamente en forma personal o dentro de la organización en la cual se está usando el programa.
      
	>  c. Hacer un acuerdo directo con el autor de este programa.

3. Cobrar un honorario razonable por instalar, configurar y
   dar soporte en el uso de este programa, dejando constancia
   expresa que el código es libre y gratuito.

4. Utilizar las rutinas y algoritmos incluidos en el Programa,
   como parte de otro programa libre y gratuito.

NO está permitido:

1. Vender el programa, como tal. La retribución que se puede
   obtener es por el trabajo propio, no por el producto de un
   trabajo ajeno.

2. Utilizar el programa como parte de otro sistema informático
   sujeto a distribución comercial.


###Limitación de Responsabilidad

Este programa ha sido desarrollado con la idea de ser útil, pero se 
distribuye 'tal como está', sin garantía alguna, ya  sea directa o 
indirecta, respecto de algún uso particular o del rendimiento y calidad 
del trabajo efectuado con él.

(c) Víctor Araya R., 2009 - <varaya@programmer.net>
