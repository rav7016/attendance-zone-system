import '../models/constituency.dart';
import 'database_service.dart';

class ConstituencyDataService {
  static const List<Map<String, dynamic>> _constituencyData = [
    {
      'constituencyNo': 1,
      'name': 'Grand River North West and Port Louis West',
      'electoralPopulation': 33839,
      'ethnicMajority': 'Creole/Hindu',
    },
    {
      'constituencyNo': 2,
      'name': 'Port Louis South and Port Louis Central',
      'electoralPopulation': 30950,
      'ethnicMajority': 'Muslim/Sino Mauritian/Creole',
    },
    {
      'constituencyNo': 3,
      'name': 'Port Louis Maritime and Port Louis East',
      'electoralPopulation': 31325,
      'ethnicMajority': 'Muslim',
    },
    {
      'constituencyNo': 4,
      'name': 'Port Louis North and Montagne Longue',
      'electoralPopulation': 59584,
      'ethnicMajority': 'Hindu/Creole',
    },
    {
      'constituencyNo': 5,
      'name': 'Pamplemousses and Triolet',
      'electoralPopulation': 59580,
      'ethnicMajority': 'Hindu',
    },
    {
      'constituencyNo': 6,
      'name': 'Grand Baie and Poudre d\'Or',
      'electoralPopulation': 59103,
      'ethnicMajority': 'Hindu',
    },
    {
      'constituencyNo': 7,
      'name': 'Piton and Riviere du Rempart',
      'electoralPopulation': 46516,
      'ethnicMajority': 'Hindu',
    },
    {
      'constituencyNo': 8,
      'name': 'Quartier Militaire and Moka',
      'electoralPopulation': 49313,
      'ethnicMajority': 'Hindu',
    },
    {
      'constituencyNo': 9,
      'name': 'Flacq and Bon Accueil',
      'electoralPopulation': 60301,
      'ethnicMajority': 'Multi Ethnic',
    },
    {
      'constituencyNo': 10,
      'name': 'Montagne Blanche and Grand River South East',
      'electoralPopulation': 56663,
      'ethnicMajority': 'Hindu',
    },
    {
      'constituencyNo': 11,
      'name': 'Vieux Grand Port and Rose Belle',
      'electoralPopulation': 46167,
      'ethnicMajority': 'Hindu',
    },
    {
      'constituencyNo': 12,
      'name': 'Mahebourg and Plaine Magnien',
      'electoralPopulation': 41732,
      'ethnicMajority': 'Hindu',
    },
    {
      'constituencyNo': 13,
      'name': 'Riviere des Anguilles and Souillac',
      'electoralPopulation': 37142,
      'ethnicMajority': 'Muslim/Hindu/Creole',
    },
    {
      'constituencyNo': 14,
      'name': 'Savanne and Black River',
      'electoralPopulation': 51997,
      'ethnicMajority': 'Creole/Hindu',
    },
    {
      'constituencyNo': 15,
      'name': 'La Caverne and Phoenix',
      'electoralPopulation': 61231,
      'ethnicMajority': 'Muslim/Hindu/Creole',
    },
    {
      'constituencyNo': 16,
      'name': 'Vacoas and Floreal',
      'electoralPopulation': 46651,
      'ethnicMajority': 'Hindu/Creole',
    },
    {
      'constituencyNo': 17,
      'name': 'Curepipe and Midlands',
      'electoralPopulation': 47428,
      'ethnicMajority': 'Multi Ethnic',
    },
    {
      'constituencyNo': 18,
      'name': 'Belle Rose and Quatre Bornes',
      'electoralPopulation': 60795,
      'ethnicMajority': 'Multi Ethnic',
    },
    {
      'constituencyNo': 19,
      'name': 'Stanley and Rose Hill',
      'electoralPopulation': 41956,
      'ethnicMajority': 'Multi Ethnic',
    },
    {
      'constituencyNo': 20,
      'name': 'Beau Bassin and Petite Riviere',
      'electoralPopulation': 47598,
      'ethnicMajority': 'Multi Ethnic',
    },
    {
      'constituencyNo': 21,
      'name': 'Rodrigues',
      'electoralPopulation': 32986,
      'ethnicMajority': 'Rodriguan Creole',
    },
  ];

  static Future<void> initializeConstituencyData() async {
    final db = DatabaseService.instance;

    // Check if data is already loaded
    if (db.totalConstituencies > 0) {
      return; // Data already exists
    }

    // Load all constituency data
    for (final data in _constituencyData) {
      final constituency = Constituency(
        constituencyNo: data['constituencyNo'],
        name: data['name'],
        electoralPopulation: data['electoralPopulation'],
        ethnicMajority: data['ethnicMajority'],
      );

      await db.saveConstituency(constituency);
    }
  }

  static Map<String, dynamic> getConstituencyStatistics() {
    final db = DatabaseService.instance;
    final constituencies = db.getAllConstituencies();

    if (constituencies.isEmpty) {
      return {
        'totalConstituencies': 0,
        'totalElectoralPopulation': 0,
        'averagePopulation': 0,
        'ethnicBreakdown': <String, int>{},
      };
    }

    final totalPopulation = constituencies.fold(
      0,
      (sum, constituency) => sum + constituency.electoralPopulation,
    );

    final ethnicBreakdown = <String, int>{};
    for (final constituency in constituencies) {
      final ethnicGroups = constituency.ethnicMajority.split('/');
      for (final group in ethnicGroups) {
        final cleanGroup = group.trim();
        ethnicBreakdown[cleanGroup] = (ethnicBreakdown[cleanGroup] ?? 0) + 1;
      }
    }

    return {
      'totalConstituencies': constituencies.length,
      'totalElectoralPopulation': totalPopulation,
      'averagePopulation': (totalPopulation / constituencies.length).round(),
      'ethnicBreakdown': ethnicBreakdown,
      'largestConstituency': constituencies.reduce(
        (a, b) => a.electoralPopulation > b.electoralPopulation ? a : b,
      ),
      'smallestConstituency': constituencies.reduce(
        (a, b) => a.electoralPopulation < b.electoralPopulation ? a : b,
      ),
    };
  }

  static List<Constituency> searchConstituencies(String query) {
    final db = DatabaseService.instance;
    final constituencies = db.getAllConstituencies();

    if (query.isEmpty) return constituencies;

    final lowerQuery = query.toLowerCase();
    return constituencies.where((constituency) {
      return constituency.name.toLowerCase().contains(lowerQuery) ||
          constituency.ethnicMajority.toLowerCase().contains(lowerQuery) ||
          constituency.constituencyNo.toString().contains(query);
    }).toList();
  }
}
