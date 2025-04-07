import requests
LOGGING_API_URL = "http://localhost:8080/logging/add"
import streamlit as st;

def log_movie_click(user_id, movie_id):
    """Send a POST request to log movie click with request parameters"""
    params = {
        "userId": int(user_id),
        "movieId": int(movie_id)
    }
    
    try:
        response = requests.post(LOGGING_API_URL, params=params)  # Sending as request params
        if response.status_code == 200:
            st.success("Click logged successfully!")  # Optional success message
        else:
            st.warning(f"Failed to log click: {response.status_code}")
    except Exception as e:
        st.error(f"Error logging click: {e}")

