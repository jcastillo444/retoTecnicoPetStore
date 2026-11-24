# Reto técnico – Pruebas API PetStore con Karate

Pruebas automatizadas del servicio de usuarios de [PetStore](https://petstore.swagger.io/), hechas con **Karate 1.5.0**, **Java 17**, **Maven** y **JUnit 5**.

Cada caso es un escenario independiente: genera sus propios datos, prepara sus precondiciones y al final elimina el usuario de prueba. Por eso cualquier escenario se puede ejecutar solo y en cualquier orden.

| # | Escenario | Tag | Precondición | Petición probada |
|---|---|---|---|---|
| 1 | Crear un usuario | `@crear` | – | `POST /user` |
| 2 | Buscar el usuario creado | `@buscar` | Usuario creado | `GET /user/{username}` |
| 3 | Actualizar el nombre y el correo del usuario | `@actualizar` | Usuario creado | `PUT /user/{username}` |
| 4 | Buscar el usuario actualizado | `@buscar-actualizado` | Usuario creado y actualizado | `GET /user/{username}` |
| 5 | Eliminar el usuario | `@eliminar` | Usuario creado | `DELETE /user/{username}` y `GET` → 404 |
| 6 | *Extra:* buscar un usuario que no existe | `@negativo` | – | `GET /user/{username}` → 404 |
| 7 | *Hallazgo:* el `PUT` ignora el username de la URL | `@hallazgo` | Usuario creado | `PUT /user/userSofka` con el body de otro usuario → 200 y se modifica el usuario del body (ver Conclusiones, hallazgo 1) |

---

## 1. Requisitos previos

| Herramienta | Versión usada | Cómo comprobarlo |
|---|---|---|
| Java JDK | 17 | `java -version` |
| Maven | 3.9.9 | `mvn -v` |
| Git | cualquiera | `git --version` |
| Acceso a Internet | – | Las pruebas consumen `https://petstore.swagger.io/v2` |

> Si no tienes Maven instalado, puedes abrir el proyecto en IntelliJ IDEA, que trae Maven incluido (ver la opción B del paso 3).

## 2. Descargar el proyecto

```bash
git clone https://github.com/jcastillo444/retoTecnicoPetStore.git
cd retoTecnicoPetStore
```

> Para ver el resultado de la última ejecución sin correr nada, abre `reportes/karate-summary.html` en el navegador (ver paso 4).

## 3. Ejecutar las pruebas

**Opción A – Consola**

```bash
mvn clean test
```

**Opción B – IntelliJ IDEA**

1. *File > Open* y selecciona la carpeta del proyecto (se importa como proyecto Maven).
2. Abre `src/test/java/co/com/petstore/UsuarioRunner.java`.
3. Clic en el ícono ▶ junto a `testUsuarios()` y elige *Run*.

**Ejecutar solo un grupo de escenarios (tags)**

```bash
mvn clean test -Dkarate.options="--tags @actualizar"
mvn clean test -Dkarate.options="--tags @buscar,@eliminar"
```

En la consola solo se muestran las peticiones, las respuestas y los mensajes `print` de Karate (configurado en `logback-test.xml`). El log completo queda en `target/karate.log`.

## 4. Ver los resultados

Al terminar, Karate genera el reporte en la carpeta **`reportes/`** en la raíz del proyecto:

- `reportes/karate-summary.html` – resumen de la ejecución (ábrelo en el navegador).
- `reportes/co.com.petstore.usuario.html` – detalle paso a paso, con la petición (URL, headers, body) y la respuesta de cada llamada, además de los mensajes `print` con las entradas y salidas.
- `reportes/karate-timeline.html` – línea de tiempo de la ejecución.

La carpeta `reportes/` se sube al repositorio como evidencia de la última ejecución, así que el reporte se puede abrir apenas se descarga el proyecto, sin ejecutar las pruebas. Al volver a ejecutar, el reporte se reemplaza por el de la nueva ejecución.

## 5. Estructura del proyecto

```
├── pom.xml                                   Dependencias (karate-junit5) y plugins
├── Readme.md                                 Este archivo
├── Conclusiones.md                           Hallazgos y conclusiones
├── reportes/                                 Reportes HTML de Karate (evidencia)
└── src/test/java
    ├── karate-config.js                      Variables globales: baseUrl, timeouts, reintentos
    ├── logback-test.xml                      Nivel de log: solo peticiones, respuestas y print
    └── co/com/petstore
        ├── UsuarioRunner.java                Runner JUnit 5
        ├── usuario.feature                   Escenarios de prueba
        ├── helpers                           Features reutilizables (@ignore, no se ejecutan solos)
        │   ├── crear-usuario.feature         Precondición: crea el usuario
        │   ├── actualizar-usuario.feature    Precondición: actualiza nombre y correo
        │   └── eliminar-usuario.feature      Limpieza al final de cada escenario
        └── data
            ├── usuario.json                  Entrada: usuario a crear
            ├── actualizacion-usuario.json    Entrada: cambios de nombre y correo
            └── esquema-usuario.json          Esquema esperado de la respuesta GET
```

## 6. Entradas, salidas y variables

| Variable | Origen | Uso |
|---|---|---|
| `baseUrl` | `karate-config.js` | URL base de la API (`https://petstore.swagger.io/v2`) |
| `timestamp` | Generada en el `Background` de cada escenario | Hace únicos el `id`, el `username` y los correos, para no chocar con datos de otras personas en la API pública |
| `userId`, `username` | Derivadas de `timestamp` | Identifican al usuario en todas las peticiones |
| `usuario` | `data/usuario.json` | Body del `POST` y valores esperados del primer `GET` |
| `cambios` | `data/actualizacion-usuario.json` | Solo `firstName` y `email` |
| `usuarioActualizado` | `usuario` + `cambios` | Body del `PUT` y valores esperados del segundo `GET` |
| `esquemaUsuario` | `data/esquema-usuario.json` | Valida los tipos de datos de la respuesta |

Salidas validadas en cada escenario:

| Escenario | Status | Respuesta esperada |
|---|---|---|
| Crear | 200 | `{ code: 200, type: "unknown", message: "<id>" }` |
| Buscar | 200 | El usuario completo, igual a lo enviado |
| Actualizar | 200 | `{ code: 200, type: "unknown", message: "<id>" }` |
| Buscar actualizado | 200 | Nombre y correo nuevos; el resto de campos sin cambios |
| Eliminar | 200 | `{ code: 200, type: "unknown", message: "<username>" }` |
| Buscar eliminado | 404 | `{ code: 1, type: "error", message: "User not found" }` |
| Usuario inexistente | 404 | `{ code: 1, type: "error", message: "User not found" }` |
| Hallazgo: `PUT /user/userSofka` | 200 | Se modifica el usuario del body y `userSofka` sigue respondiendo 404 |
