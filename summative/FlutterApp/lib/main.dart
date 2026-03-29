import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() => runApp(const UnemploymentPredictorApp());

class UnemploymentPredictorApp extends StatelessWidget {
  const UnemploymentPredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unemployment Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const PredictionPage(),
    );
  }
}

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  // controllers for all 25 input fields
  final yearCtrl = TextEditingController();
  final gdpCtrl = TextEditingController();
  final litFemaleCtrl = TextEditingController();
  final litMaleCtrl = TextEditingController();
  final litAdultCtrl = TextEditingController();
  final primCompCtrl = TextEditingController();
  final ptrPrimCtrl = TextEditingController();
  final enrollPrimCtrl = TextEditingController();
  final primTeachersCtrl = TextEditingController();
  final lowerSecCompCtrl = TextEditingController();
  final ptrSecCtrl = TextEditingController();
  final enrollSecCtrl = TextEditingController();
  final secTeachersCtrl = TextEditingController();
  final enrollTertCtrl = TextEditingController();
  final govtSpendGovtCtrl = TextEditingController();
  final govtSpendGdpCtrl = TextEditingController();
  final lfAdvancedCtrl = TextEditingController();
  final lfBasicCtrl = TextEditingController();
  final lfIntermCtrl = TextEditingController();
  final lfFemaleCtrl = TextEditingController();
  final lfTotalCtrl = TextEditingController();
  final neetCtrl = TextEditingController();
  final pop1564Ctrl = TextEditingController();
  final popTotalCtrl = TextEditingController();
  final regionCtrl = TextEditingController();

  String _predictionResult = '';
  bool _isError = false;
  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in [
      yearCtrl, gdpCtrl, litFemaleCtrl, litMaleCtrl, litAdultCtrl,
      primCompCtrl, ptrPrimCtrl, enrollPrimCtrl, primTeachersCtrl,
      lowerSecCompCtrl, ptrSecCtrl, enrollSecCtrl, secTeachersCtrl,
      enrollTertCtrl, govtSpendGovtCtrl, govtSpendGdpCtrl,
      lfAdvancedCtrl, lfBasicCtrl, lfIntermCtrl, lfFemaleCtrl,
      lfTotalCtrl, neetCtrl, pop1564Ctrl, popTotalCtrl, regionCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // map of field names to their controllers for validation
  Map<String, TextEditingController> get _fieldControllers => {
    'Year': yearCtrl,
    'GDP Per Capita': gdpCtrl,
    'Literacy Rate Female': litFemaleCtrl,
    'Literacy Rate Male': litMaleCtrl,
    'Literacy Rate Adult': litAdultCtrl,
    'Primary Completion Rate': primCompCtrl,
    'Pupil Teacher Ratio Primary': ptrPrimCtrl,
    'School Enrollment Primary': enrollPrimCtrl,
    'Primary Teachers': primTeachersCtrl,
    'Lower Secondary Completion Rate': lowerSecCompCtrl,
    'Pupil Teacher Ratio Secondary': ptrSecCtrl,
    'School Enrollment Secondary': enrollSecCtrl,
    'Secondary Teachers': secTeachersCtrl,
    'School Enrollment Tertiary': enrollTertCtrl,
    'Govt Education Spending Govt Pct': govtSpendGovtCtrl,
    'Govt Education Spending GDP Pct': govtSpendGdpCtrl,
    'Labor Force Advanced Education': lfAdvancedCtrl,
    'Labor Force Basic Education': lfBasicCtrl,
    'Labor Force Intermediate Education': lfIntermCtrl,
    'Labor Force Female Pct': lfFemaleCtrl,
    'Labor Force Total': lfTotalCtrl,
    'NEET Rate': neetCtrl,
    'Population 15-64 Pct': pop1564Ctrl,
    'Population Total': popTotalCtrl,
    'Region Encoded': regionCtrl,
  };

  void _fillSampleData() {
    yearCtrl.text = '2013';
    gdpCtrl.text = '7674.86';
    litFemaleCtrl.text = '97.98';
    litMaleCtrl.text = '98.75';
    litAdultCtrl.text = '98.35';
    primCompCtrl.text = '97.97';
    ptrPrimCtrl.text = '17.63';
    enrollPrimCtrl.text = '99.37';
    primTeachersCtrl.text = '14388';
    lowerSecCompCtrl.text = '42.30';
    ptrSecCtrl.text = '13.04';
    enrollSecCtrl.text = '98.88';
    secTeachersCtrl.text = '39843';
    enrollTertCtrl.text = '66.54';
    govtSpendGovtCtrl.text = '11.44';
    govtSpendGdpCtrl.text = '4.06';
    lfAdvancedCtrl.text = '73.49';
    lfBasicCtrl.text = '24.93';
    lfIntermCtrl.text = '62.00';
    lfFemaleCtrl.text = '46.65';
    lfTotalCtrl.text = '3378735';
    neetCtrl.text = '24.70';
    pop1564Ctrl.text = '67.04';
    popTotalCtrl.text = '7265115';
    regionCtrl.text = '1';
  }

  Future<void> _predict() async {
    // check each field and report which ones fail
    final controllers = _fieldControllers;
    List<String> invalidFields = [];
    for (var entry in controllers.entries) {
      if (entry.value.text.trim().isEmpty) {
        invalidFields.add('${entry.key} is empty');
      } else {
        try {
          double.parse(entry.value.text.trim());
        } catch (e) {
          invalidFields
              .add("${entry.key} has invalid value: '${entry.value.text}'");
        }
      }
    }

    if (invalidFields.isNotEmpty) {
      setState(() {
        _predictionResult = 'Please fix these fields:\n${invalidFields.join('\n')}';
        _isError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _predictionResult = 'Waiting for server (may take up to 60s)...';
      _isError = false;
    });

    // build request body with exact API field names
    final body = {
      "Year": int.parse(yearCtrl.text.trim()),
      "GDP_Per_Capita": double.parse(gdpCtrl.text.trim()),
      "Literacy_Rate_Female": double.parse(litFemaleCtrl.text.trim()),
      "Literacy_Rate_Male": double.parse(litMaleCtrl.text.trim()),
      "Literacy_Rate_Adult": double.parse(litAdultCtrl.text.trim()),
      "Primary_Completion_Rate": double.parse(primCompCtrl.text.trim()),
      "Pupil_Teacher_Ratio_Primary": double.parse(ptrPrimCtrl.text.trim()),
      "School_Enrollment_Primary": double.parse(enrollPrimCtrl.text.trim()),
      "Primary_Teachers": double.parse(primTeachersCtrl.text.trim()),
      "Lower_Secondary_Completion_Rate": double.parse(lowerSecCompCtrl.text.trim()),
      "Pupil_Teacher_Ratio_Secondary": double.parse(ptrSecCtrl.text.trim()),
      "School_Enrollment_Secondary": double.parse(enrollSecCtrl.text.trim()),
      "Secondary_Teachers": double.parse(secTeachersCtrl.text.trim()),
      "School_Enrollment_Tertiary": double.parse(enrollTertCtrl.text.trim()),
      "Govt_Education_Spending_Govt_Pct": double.parse(govtSpendGovtCtrl.text.trim()),
      "Govt_Education_Spending_GDP_Pct": double.parse(govtSpendGdpCtrl.text.trim()),
      "Labor_Force_Advanced_Education": double.parse(lfAdvancedCtrl.text.trim()),
      "Labor_Force_Basic_Education": double.parse(lfBasicCtrl.text.trim()),
      "Labor_Force_Intermediate_Education": double.parse(lfIntermCtrl.text.trim()),
      "Labor_Force_Female_Pct": double.parse(lfFemaleCtrl.text.trim()),
      "Labor_Force_Total": double.parse(lfTotalCtrl.text.trim()),
      "NEET_Rate": double.parse(neetCtrl.text.trim()),
      "Population_15_64_Pct": double.parse(pop1564Ctrl.text.trim()),
      "Population_Total": double.parse(popTotalCtrl.text.trim()),
      "Region_Encoded": int.parse(regionCtrl.text.trim()),
    };

    try {
      final response = await http.post(
        Uri.parse('https://linear-regression-model-cios.onrender.com/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _predictionResult =
              'Predicted Unemployment Rate: ${result['prediction']}%';
          _isError = false;
        });
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _predictionResult =
              'Error: ${error['detail'] ?? 'Something went wrong'}';
          _isError = true;
        });
      }
    } on TimeoutException {
      setState(() {
        _predictionResult =
            'Request timed out. The server may be starting up — please try again in 30 seconds.';
        _isError = true;
      });
    } catch (e) {
      setState(() {
        _predictionResult =
            'Connection error: Could not reach the API. Please try again.';
        _isError = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unemployment Predictor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Predict unemployment rate for developing countries based on '
              'education and economic indicators.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 20),

            // General
            _sectionHeader('General'),
            _buildField(yearCtrl, 'Year', 'e.g., 2015'),

            // Economic Indicators
            _sectionHeader('Economic Indicators'),
            _buildField(gdpCtrl, 'GDP Per Capita', 'e.g., 5000.0'),

            // Literacy Rates
            _sectionHeader('Literacy Rates'),
            _buildField(litFemaleCtrl, 'Literacy Rate Female (%)', 'e.g., 85.0'),
            _buildField(litMaleCtrl, 'Literacy Rate Male (%)', 'e.g., 90.0'),
            _buildField(litAdultCtrl, 'Literacy Rate Adult (%)', 'e.g., 87.0'),

            // Primary Education
            _sectionHeader('Primary Education'),
            _buildField(primCompCtrl, 'Primary Completion Rate (%)', 'e.g., 90.0'),
            _buildField(ptrPrimCtrl, 'Pupil Teacher Ratio Primary', 'e.g., 25.0'),
            _buildField(enrollPrimCtrl, 'School Enrollment Primary (%)', 'e.g., 105.0'),
            _buildField(primTeachersCtrl, 'Primary Teachers', 'e.g., 50000'),

            // Secondary Education
            _sectionHeader('Secondary Education'),
            _buildField(lowerSecCompCtrl, 'Lower Secondary Completion Rate (%)', 'e.g., 65.0'),
            _buildField(ptrSecCtrl, 'Pupil Teacher Ratio Secondary', 'e.g., 18.0'),
            _buildField(enrollSecCtrl, 'School Enrollment Secondary (%)', 'e.g., 75.0'),
            _buildField(secTeachersCtrl, 'Secondary Teachers', 'e.g., 80000'),

            // Tertiary Education
            _sectionHeader('Tertiary Education'),
            _buildField(enrollTertCtrl, 'School Enrollment Tertiary (%)', 'e.g., 30.0'),

            // Government Spending
            _sectionHeader('Government Spending'),
            _buildField(govtSpendGovtCtrl, 'Education Spending (% of Govt)', 'e.g., 15.0'),
            _buildField(govtSpendGdpCtrl, 'Education Spending (% of GDP)', 'e.g., 4.5'),

            // Labor Force
            _sectionHeader('Labor Force'),
            _buildField(lfAdvancedCtrl, 'Labor Force Advanced Education (%)', 'e.g., 25.0'),
            _buildField(lfBasicCtrl, 'Labor Force Basic Education (%)', 'e.g., 40.0'),
            _buildField(lfIntermCtrl, 'Labor Force Intermediate Education (%)', 'e.g., 55.0'),
            _buildField(lfFemaleCtrl, 'Labor Force Female (%)', 'e.g., 45.0'),
            _buildField(lfTotalCtrl, 'Labor Force Total', 'e.g., 5000000'),
            _buildField(neetCtrl, 'NEET Rate (%)', 'e.g., 20.0'),

            // Demographics
            _sectionHeader('Demographics'),
            _buildField(pop1564Ctrl, 'Population 15-64 (%)', 'e.g., 60.0'),
            _buildField(popTotalCtrl, 'Population Total', 'e.g., 30000000'),

            // Region
            _sectionHeader('Region'),
            _buildField(
              regionCtrl,
              'Region Encoded',
              '0=East Asia, 1=Europe, 2=Latin America, 3=MENA, 4=South Asia, 5=Sub-Saharan Africa',
            ),

            const SizedBox(height: 24),

            // Fill sample data button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _fillSampleData,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Fill Sample Data',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Predict button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _predict,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Predict',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // result display
            if (_predictionResult.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isError ? Colors.red : Colors.green,
                  ),
                ),
                child: Text(
                  _predictionResult,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isError
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}
