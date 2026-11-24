package co.com.petstore;

import com.intuit.karate.junit5.Karate;

public class UsuarioRunner {

    @Karate.Test
    Karate testUsuarios() {
        return Karate.run("usuario")
                .relativeTo(getClass())
                .reportDir("reportes")
                .backupReportDir(false);
    }
}
