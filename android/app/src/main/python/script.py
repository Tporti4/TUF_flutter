from scipy.io import wavfile
from IPython.display import Audio
# from matplotlib import pyplot as plt
import numpy as np
from scipy.signal import hilbert
from scipy.signal import find_peaks


def envelope_respiration(file_name):
    recording = "active_2feet_2.wav"
    recording = file_name

    fs, wav = wavfile.read(recording)
    analytic_signal = hilbert(wav)
    amplitude_envelope = np.abs(analytic_signal)

    t = np.arange(fs) / fs

    # print(amplitude_envelope)
    # print(type(amplitude_envelope))
    # print(max(amplitude_envelope))
    # print(np.mean(amplitude_envelope))
    # print(np.median(amplitude_envelope))
    # print(np.percentile(amplitude_envelope, 50))

    avg = np.mean(amplitude_envelope)
    peaks, properties = find_peaks(amplitude_envelope, height=avg, distance=60000)
    # print(peaks)

    notable_peak_loc = properties["peak_heights"]
    # print(notable_peak_loc)

    # print("Mean of selected peaks:", np.mean(notable_peak_loc))
    notable_peak_bool = notable_peak_loc > np.mean(notable_peak_loc)

    # print(notable_peak_bool)
    # notable_peak_loc = notable_peak_loc[notable_peak_loc > np.mean(notable_peak_loc)]
    # print(notable_peak_loc)

    peaks = peaks[notable_peak_bool == True]
    # print(peaks)


    np.diff(peaks)
    # print("Sampling Rate:", fs)

    num_breaths = len(peaks)
    # print("Number of breaths:", num_breaths)
    recording_time = len(wav) / fs
    # print("Length of recording (in seconds):", recording_time)
    respiratory_rate = 60 * num_breaths / recording_time
    respiratory_rate = round(respiratory_rate, 2)
    # print("Respiratory Rate:", respiratory_rate, "breaths per minute")
    # plt.plot(amplitude_envelope)
    # plt.plot(peaks, amplitude_envelope[peaks], "x")
    # plt.show()
