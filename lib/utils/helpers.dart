class AppHelpers {
  static String getGreetingMessage(String name) {
    int hour = DateTime.now().hour;

    String greeting;
    if (hour < 12) {
      greeting = "Bom dia,";
    } else if (hour < 18) {
      greeting = "Boa tarde,";
    } else {
      greeting = "Boa noite,";
    }

    return "$greeting $name"; // Retorna saudação com o nome
  }
}
