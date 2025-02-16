import os
from typing import Dict, Any
import warnings

class NetworkAIPredictor:
    def __init__(self, model_path: str = 'modele_ia.h5'):
        """Initialize the AI predictor with fallback if model is not available"""
        self.model = None
        self.model_path = model_path
        self.is_fallback_mode = True

        try:
            if os.path.exists(model_path):
                # Only import tensorflow if model exists to avoid unnecessary loading
                import tensorflow as tf
                self.model = tf.keras.models.load_model(model_path)
                self.is_fallback_mode = False
                print(f"Modèle AI chargé depuis {model_path}")
            else:
                warnings.warn(f"Modèle {model_path} non trouvé. Utilisation du mode dégradé.")
        except Exception as e:
            warnings.warn(f"Erreur lors du chargement du modèle: {str(e)}. Utilisation du mode dégradé.")

    def _calculate_signal_quality(self, signal_strength: float) -> float:
        """Calculate quality score based on signal strength"""
        # Convert dBm to quality percentage (typical WiFi ranges from -50 to -100 dBm)
        if signal_strength >= -50:
            return 1.0
        elif signal_strength <= -100:
            return 0.0
        else:
            return (signal_strength + 100) / 50

    def _extract_signal_strength(self, network_info: str) -> float:
        """Extract signal strength from network info string"""
        try:
            if "Signal" in network_info:
                signal_str = network_info.split("Signal")[1].split("dBm")[0]
                return float(signal_str.strip(" :=-"))
        except:
            pass
        return -100.0  # Default poor signal if not found

    def predict_network_quality(self, network_data: Dict[str, Any]) -> Dict[str, float]:
        """
        Predict network quality using either the AI model or fallback heuristics
        """
        try:
            if not self.is_fallback_mode and self.model is not None:
                # Use AI model for prediction when available
                signals = []
                for network_type, info in network_data.items():
                    if isinstance(info, str):
                        signal_strength = self._extract_signal_strength(info)
                        signals.append(signal_strength)

                if signals:
                    # Use the model for prediction
                    import numpy as np
                    prediction = self.model.predict(np.array([signals]), verbose=0)
                    return {
                        "quality_score": float(prediction[0][0]),
                        "reliability": 0.95  # High reliability with model
                    }

            # Fallback mode or model prediction failed
            total_quality = 0.0
            valid_networks = 0

            for network_type, info in network_data.items():
                if isinstance(info, str):
                    signal_strength = self._extract_signal_strength(info)
                    if signal_strength > -100:  # Only count valid signals
                        quality = self._calculate_signal_quality(signal_strength)
                        total_quality += quality
                        valid_networks += 1

            if valid_networks > 0:
                average_quality = total_quality / valid_networks
                return {
                    "quality_score": float(average_quality),
                    "reliability": 0.7  # Lower reliability in fallback mode
                }

            return {
                "quality_score": 0.0,
                "reliability": 0.5
            }

        except Exception as e:
            print(f"Erreur lors de la prédiction: {str(e)}")
            return {
                "quality_score": 0.0,
                "reliability": 0.0
            }