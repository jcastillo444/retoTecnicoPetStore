# Hallazgos y conclusiones

## Hallazgos sobre la API PetStore (`/user`)

1. **El `PUT /user/{username}` no tiene en cuenta el username de la URL.** Se envió `PUT /user/userSofka`, un usuario que no existe, con el body de otro usuario creado en la prueba. La API respondió **200**, modificó al usuario del body y `userSofka` siguió sin existir (404 antes y después). La actualización se hace por el contenido del body (`id`/`username`) y no por el recurso indicado en la URL. Esto no es el comportamiento REST esperado: lo correcto sería responder 404 porque `userSofka` no existe, o 400 porque la URL y el body no coinciden. Además, permitiría modificar un usuario distinto al que indica la URL. El escenario `@hallazgo` reproduce este caso en cada ejecución: si algún día la API lo corrige, ese escenario fallará y avisará que el hallazgo ya no aplica.
2. **Las respuestas de escritura no son descriptivas.** `POST` y `PUT` responden `{ "code": 200, "type": "unknown", "message": "<id>" }`, y `DELETE` responde `{ ..., "message": "<username>" }`. El campo `type` siempre vale `"unknown"` y el `message` cambia de significado según la operación. Para validar el resultado hay que volver a consultar el recurso.
3. **El `GET` devuelve la contraseña en texto plano.** Es un problema de seguridad en una API real: los datos sensibles nunca deberían salir en la respuesta.
4. **No pide autenticación** para crear, modificar ni eliminar usuarios. Cualquiera puede borrar el usuario de otra persona.
5. **El ambiente es público y compartido.** Con datos fijos (por ejemplo `id: 100`, `username: jonacast`) otra persona puede sobrescribir o borrar el usuario a mitad de la prueba. Por eso la prueba genera `id`, `username` y correos únicos en cada ejecución.
6. **Tiempos de respuesta estables.** Cada llamada respondió en unos 300 ms (la primera, en unos 900 ms por el establecimiento de la conexión), y cada consulta devolvió el dato correcto al primer intento.
7. **El usuario inexistente responde 404** con `{ "code": 1, "type": "error", "message": "User not found" }`, un comportamiento correcto y consistente.

## Decisión de diseño: escenarios independientes

**Lo recomendado en Karate.** Cada `Scenario` debe poder ejecutarse solo, sin depender de que otro haya corrido antes. Karate no garantiza el orden cuando las pruebas se ejecutan en paralelo (`Runner.parallel()`). Además, si un escenario depende del anterior, no se puede ejecutar aislado (por tag o desde el IDE), y una sola falla, por ejemplo en "Crear", hace fallar en cascada a todos los demás y oculta dónde está el problema real.

**Lo que se hizo.** El enunciado pide 5 casos concretos, y en el reporte conviene ver cada uno como un escenario con su propio resultado. Para mantener esa separación sin la dependencia entre escenarios:

- El `Background` genera datos únicos (`id`, `username`, correos) antes de cada escenario.
- Cada escenario prepara su propia precondición con features reutilizables (`helpers/crear-usuario.feature`, `helpers/actualizar-usuario.feature`) y prueba solo su caso. Por ejemplo, "Buscar el usuario actualizado" crea y actualiza su propio usuario antes de consultarlo.
- Al terminar cada escenario, pase o falle, `afterScenario` elimina el usuario de prueba para no dejar datos en la API pública.

**Costo asumido.** Se hacen más llamadas a la API, porque cada escenario crea su propio usuario. Se acepta a cambio de pruebas repetibles, ejecutables en cualquier orden o de forma aislada, y con fallas fáciles de ubicar.

## Conclusiones del ejercicio

1. Con Karate se cubrieron los 5 casos pedidos (crear, buscar, actualizar nombre y correo, buscar actualizado y eliminar), cada uno como un escenario independiente. Las precondiciones se preparan con features reutilizables (`call`) y la limpieza con `afterScenario`, así que cada escenario se puede ejecutar solo, en cualquier orden y de forma repetible, y una falla no arrastra a los demás.
2. Separar los datos de prueba en archivos JSON (`data/`) y la configuración en `karate-config.js` deja claras las entradas y facilita cambiar de ambiente o de datos sin tocar los escenarios.
3. Las validaciones combinan status, igualdad exacta del body, esquema (`#number`, `#string`, `#regex`) y que los campos que no se modificaron conserven su valor. Así se detectan cambios no deseados, no solo el "200 OK".
4. Karate da en un mismo DSL (Gherkin) las peticiones HTTP, las aserciones sobre JSON, los reintentos y los reportes HTML, sin escribir código Java de soporte. Esto reduce la curva de aprendizaje frente a librerías como REST-Assured.
5. Los reportes HTML de Karate muestran la petición y la respuesta completas de cada paso, que sirven como evidencia reproducible de la ejecución (carpeta `reportes/`).
6. Recomendación: en una API propia, los hallazgos 1, 3 y 4 deberían reportarse como defectos de seguridad y de diseño.
7. Se optó por dejar el informe en el repo solo para dar a conocer su resultado sin la necesidad de ejecutarlo, sin embargo esto no es buena práctica pues este informe genera muchos archivos temporales que cambian constantemente.
