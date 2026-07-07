class HeatShiftConfig {
  String systemMode;
  String fuelType;
  double consumptionRate;
  double condenserKw;
  double activationTempHeating;
  double activationTempCooling;

  HeatShiftConfig({
    this.systemMode = 'cool_down',
    this.fuelType = 'oil',
    this.consumptionRate = 1.0,
    this.condenserKw = 2.5,
    this.activationTempHeating = 72.0,
    this.activationTempCooling = 72.0,
  });

  Map<String, dynamic> toJson(String pin) => {
        'pin': pin,
        'system_mode': systemMode,
        'fuel_type': fuelType,
        'consumption_rate': consumptionRate,
        'condenser_kw': condenserKw,
        'activation_temp_heating': activationTempHeating,
        'activation_temp_cooling': activationTempCooling,
      };

  String get systemModeLabel =>
      systemMode == 'cool_down' ? 'Cool Down' : 'Heat Up';

  String get fuelTypeLabel {
    switch (fuelType) {
      case 'oil':
        return 'Oil';
      case 'lpg':
        return 'LPG / Propane';
      case 'natural_gas':
        return 'Natural Gas';
      case 'heat_pump':
        return 'Heat Pump';
      default:
        return 'Oil';
    }
  }

  String get consumptionRateLabel {
    switch (fuelType) {
      case 'oil':
      case 'lpg':
        return 'Nozzle Size (gal/hr)';
      case 'natural_gas':
        return 'BTU Rate (thm/hr)';
      case 'heat_pump':
        return 'kW Rating';
      default:
        return 'Nozzle Size (gal/hr)';
    }
  }
}
