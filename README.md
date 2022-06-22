# sonarqube-java8u252-issue

[First mention](https://community.sonarsource.com/t/connectionshutdownexception-in-maven-plugin-with-java-8-update-252/23913) by colleague Hans-Peter Keck

Solved by [protocol negotiation in traefik](https://doc.traefik.io/traefik/v2.5/https/tls/#alpn-protocols)

This also seems to be a non-issue nowadays because the plugins downloaded from the server cannot be executed by Java 8.
