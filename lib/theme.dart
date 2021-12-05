import 'package:flutter/material.dart';

const kPrimaryColor = Color(0xFFb5179e);
const kSecondaryColor = Color(0xFFdeaaff);
const kContentColorLightTheme = Color(0xFF1D1D35);
const kContentColorDarkTheme = Color(0xFFF5FCF9);
const kWarninngColor = Color(0xFFF3BB1C);
const kErrorColor = Color(0xFFF03738);

const kDefaultPadding = 20.0;

ThemeData MainThemeData() {
  return ThemeData(
    cardTheme: CardTheme(
      color: Colors.orange,
    ),
    //cardColor: kErrorColor,
    fontFamily: "Sanchez",
    indicatorColor: kPrimaryColor,
    backgroundColor: Colors.black,

    primaryColor: kPrimaryColor,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: appBarTheme,
    iconTheme: IconThemeData(color: kContentColorLightTheme),
    //buttonTheme: ButtonThemeData(),
    textTheme: TextTheme(
      bodyText1: TextStyle(color: kContentColorLightTheme, fontSize: 16),
    ),
    colorScheme: ColorScheme.light(
      primary: kPrimaryColor,
      secondary: kSecondaryColor,
      error: kErrorColor,
    ),
  );
}

final appBarTheme = AppBarTheme(centerTitle: true, elevation: 20);
