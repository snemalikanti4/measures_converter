import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MeasuresConverterApp());
}

/// Root app widget with basic theming.
class MeasuresConverterApp extends StatelessWidget {
  const MeasuresConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Measures Converter',
      theme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.compact,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            backgroundColor: Colors.indigo.withOpacity(0.08),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.compact,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            backgroundColor: Colors.indigo.withOpacity(0.18),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const ConverterPage(),
    );
  }
}

/// Supported conversion categories.
enum Category { length, weight }

/// Map of units per category and their conversion factor to a base unit.
/// For length the base unit is meter, for weight the base unit is kilogram.
final Map<Category, Map<String, double>> kUnitFactors = {
  Category.length: {
    // Metric
    'millimeters (mm)': 0.001,
    'centimeters (cm)': 0.01,
    'meters (m)': 1.0,
    'kilometers (km)': 1000.0,
    // Imperial
    'inches (in)': 0.0254,
    'feet (ft)': 0.3048,
    'yards (yd)': 0.9144,
    'miles (mi)': 1609.344,
  },
  Category.weight: {
    // Metric
    'grams (g)': 0.001,
    'kilograms (kg)': 1.0,
    'metric tons (t)': 1000.0,
    // Imperial
    'ounces (oz)': 0.028349523125,
    'pounds (lb)': 0.45359237,
    'stones (st)': 6.35029318,
  },
};

/// Main converter screen.
class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final _formKey = GlobalKey<FormState>();
  final _inputController = TextEditingController();

  Category _category = Category.length;
  late String _fromUnit;
  late String _toUnit;
  String _result = '';

  @override
  void initState() {
    super.initState();
    // Initialize default units for the initial category.
    final units = _unitsFor(_category);
    _fromUnit = units.first;
    _toUnit = units[3];
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  /// Returns the list of unit names for a given category.
  List<String> _unitsFor(Category category) => kUnitFactors[category]!.keys.toList();

  /// Performs the conversion using base-unit factors.
  void _convert() {
    if (!_formKey.currentState!.validate()) return;
    final value = double.parse(_inputController.text);

    final factorMap = kUnitFactors[_category]!;
    final fromFactor = factorMap[_fromUnit]!; // to base
    final toFactor = factorMap[_toUnit]!; // to base

    // Convert: input -> base -> target
    final baseValue = value * fromFactor;
    final converted = baseValue / toFactor;

    setState(() {
      _result = _formatResult(converted);
    });
  }

  /// Simple result formatting with trimming of trailing zeros.
  String _formatResult(double v) {
    final s = v.toStringAsFixed(6);
    return s.replaceFirst(RegExp(r"\.0{1,6}"), '').replaceFirst(RegExp(r"0+$"), '');
  }

  /// Swaps from/to units.
  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
    });
    if (_inputController.text.trim().isNotEmpty) {
      _convert();
    }
  }

  /// Builds a labeled dropdown for unit selection.
  Widget _buildUnitDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    final units = _unitsFor(_category);
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      items: units
          .map((u) => DropdownMenuItem<String>(value: u, child: Text(u)))
          .toList(),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      menuMaxHeight: 320,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isNarrow = mq.size.width < 380;
    final hPad = isNarrow ? 12.0 : 16.0;
    final vSpace = isNarrow ? 12.0 : 16.0;
    final units = _unitsFor(_category);
    if (!units.contains(_fromUnit) || !units.contains(_toUnit)) {
      // Reset units when category changes.
      _fromUnit = units.first;
      _toUnit = units.length > 1 ? units[1] : units.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Measures Converter'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(hPad, vSpace, hPad, vSpace + mq.viewInsets.bottom * 0.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Category selector (Length/Weight).
                    DropdownButtonFormField<Category>(
                      initialValue: _category,
                      onChanged: (c) => setState(() {
                        _category = c!;
                        _result = '';
                      }),
                      items: const [
                        DropdownMenuItem(value: Category.length, child: Text('Length (Metric ↔ Imperial)')),
                        DropdownMenuItem(value: Category.weight, child: Text('Weight (Metric ↔ Imperial)')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    SizedBox(height: vSpace),

                    // Input value.
                    TextFormField(
                      controller: _inputController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Enter value',
                        hintText: 'e.g. 3.5',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      validator: (text) {
                        if (text == null || text.trim().isEmpty) return 'Please enter a value';
                        final v = double.tryParse(text.trim());
                        if (v == null) return 'Enter a valid number';
                        if (v < 0) return 'Value cannot be negative';
                        return null;
                      },
                      onFieldSubmitted: (_) => _convert(),
                    ),
                    SizedBox(height: vSpace),

                    // Units row with swap button.
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stack = constraints.maxWidth < 380;
                        final spacerW = stack ? 0.0 : 8.0;
                        final spacerH = stack ? 8.0 : 0.0;
                        final children = <Widget>[
                          Expanded(
                            child: _buildUnitDropdown(
                              label: 'From',
                              value: _fromUnit,
                              onChanged: (v) => setState(() => _fromUnit = v!),
                            ),
                          ),
                          SizedBox(width: spacerW, height: spacerH),
                          IconButton.filledTonal(
                            onPressed: _swapUnits,
                            icon: const Icon(Icons.swap_horiz),
                            tooltip: 'Swap units',
                          ),
                          SizedBox(width: spacerW, height: spacerH),
                          Expanded(
                            child: _buildUnitDropdown(
                              label: 'To',
                              value: _toUnit,
                              onChanged: (v) => setState(() => _toUnit = v!),
                            ),
                          ),
                        ];
                        return stack
                            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                children[0],
                                children[1],
                                Center(child: children[2]),
                                children[3],
                                children[4],
                              ])
                            : Row(children: children);
                      },
                    ),
                    SizedBox(height: isNarrow ? 16 : 20),

                    // Convert button.
                    FilledButton.icon(
                      onPressed: _convert,
                      icon: const Icon(Icons.calculate),
                      label: const Text('Convert'),
                    ),
                    SizedBox(height: isNarrow ? 16 : 20),

                    // Result card.
                    if (_result.isNotEmpty)
                      Card(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Result',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SizedBox(height: isNarrow ? 6 : 8),
                              Text(
                                '${_inputController.text.trim()} $_fromUnit = $_result $_toUnit',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Small helper text.
                    SizedBox(height: isNarrow ? 6 : 8),
                    Text(
                      'Tip: Select metric or imperial units on either side to convert between systems.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
