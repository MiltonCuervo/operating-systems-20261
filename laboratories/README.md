# Reporte de Laboratorio 0: Manipulación Avanzada de Shell

| Información General | Detalle |
| --- | --- |
| **Asignatura** | Sistemas Operativos |
| **Entorno** | Kali Linux (Bash Shell) |

---

### **Integrantes**

* **Milton Alejandro Cuervo Ramirez** *C.C. 1.013.587.067*
* **Diego Alejandro Rendón Suaza** *C.C. 1.007.347.028*

---

## 1. Creación del entorno de trabajo
Se creó la estructura de directorios anidados utilizando el flag `-p` para asegurar que los directorios padres se crearan automáticamente.

**Comando:**
```bash
mkdir -p ~/operating-systems-20261/laboratories/lab0
```

## 2. Navegación y registro de ruta

Se cambió el directorio de trabajo actual a la carpeta del laboratorio. Posteriormente, se capturó la ruta absoluta usando `pwd` y se redirigió la salida estándar (`stdout`) hacia un archivo de texto llamado `path.txt`.

```bash
cd ~/operating-systems-20261/laboratories/lab0
pwd > path.txt

```

## 3. Creación masiva de directorios

Se crearon cuatro directorios simultáneamente utilizando un solo comando `mkdir` con múltiples argumentos.

```bash
mkdir example music photos projects

```

## 4. Generación de archivos con Expansión de Llaves

Para cumplir con el requisito de "un solo comando", se utilizó la **Expansión de Llaves (Brace Expansion)** de Bash. Esto permite combinar la lista de carpetas con un rango secuencial numérico (`{1..100}`), generando 400 archivos instantáneamente.

```bash
touch {example,music,photos,projects}/file{1..100}

```

## 5. Eliminación selectiva por rangos

Se eliminaron los primeros 10 archivos (file1-file10) y los últimos 20 (file81-file100) de todos los directorios en una sola instrucción. Se anidaron las expansiones para seleccionar ambos rangos en el mismo comando.

```bash
rm {example,music,photos,projects}/file{{1..10},{81..100}}

```

## 6. Organización de carpetas

Se movieron los directorios `example`, `music` y `photos` dentro del directorio `projects`.

```bash
mv example music photos projects/

```

## 7. Limpieza final con registro verboso

Se eliminaron los archivos restantes (file11 a file80) que residían en la raíz de la carpeta `projects`.

* Se usó la opción `-v` (**verbose**) para que el sistema imprimiera cada archivo borrado.
* Se usó el wildcard `file*` para asegurar que solo se borraran los archivos generados y no las carpetas que acabamos de mover.
* Se redirigió el resultado al archivo `output.txt` ubicado en la raíz del laboratorio.

```bash
rm -v projects/file* > output.txt

```

---

## Glosario de Comandos y Atajos Usados

| Comando / Símbolo | Descripción |
| --- | --- |
| `mkdir -p` | Crea directorios y sus padres si no existen. |
| `>` | Redirección de salida (sobrescribe el archivo destino). |
| `{a,b,c}` | Lista de elementos para expansión. |
| `{1..100}` | Rango secuencial de números. |
| `*` | **Wildcard:** Coincide con cualquier caracter (usado para seleccionar grupos de archivos). |
| `rm -v` | Borrado verboso (muestra en pantalla lo que hace). |
| `mv` | Mover o renombrar archivos/directorios. |

```

```
