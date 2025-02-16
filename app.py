from flask import Flask, render_template
from flask_socketio import SocketIO, emit
import json
import subprocess
import threading
import time
import os
from ai_predictor import NetworkAIPredictor

app = Flask(__name__)
socketio = SocketIO(app)

# Initialize AI predictor
ai_predictor = NetworkAIPredictor()

def run_network_detection():
    """Run network detection scripts and emit results through websocket"""
    while True:
        # Always run in test mode for visualization demo
        scripts = ['wifi_detect.sh', 'lte_detect.sh', 'bluetooth_detect.sh', 'esim_detect.sh']
        network_data = {}

        for script in scripts:
            try:
                # Ensure TEST_MODE is always true for the visualization
                env = os.environ.copy()
                env['TEST_MODE'] = 'true'

                result = subprocess.run(
                    ['bash', script], 
                    env=env,
                    capture_output=True, 
                    text=True,
                    timeout=10  # Add timeout to prevent hanging
                )

                # Extract relevant information from the output
                output_lines = result.stdout.split('\n')
                cleaned_output = '\n'.join(line for line in output_lines if not line.startswith('['))
                network_data[script.replace('_detect.sh', '')] = cleaned_output

            except Exception as e:
                print(f"Error running {script}: {str(e)}")
                network_data[script.replace('_detect.sh', '')] = f"Error: {str(e)}"

        # Get AI predictions
        ai_predictions = ai_predictor.predict_network_quality(network_data)
        network_data['ai_analysis'] = ai_predictions

        # Emit the collected data
        socketio.emit('network_update', network_data)
        time.sleep(10)  # Update every 10 seconds

@app.route('/')
def index():
    return render_template('index.html')

if __name__ == '__main__':
    # Start network detection in background thread
    detection_thread = threading.Thread(target=run_network_detection)
    detection_thread.daemon = True
    detection_thread.start()

    # Start Flask server
    socketio.run(app, host='0.0.0.0', port=5000, debug=True, use_reloader=False, log_output=True)