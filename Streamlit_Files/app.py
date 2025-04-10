import streamlit as st
import requests
import app_main  # Import the main app logic

# API Endpoint for login
LOGIN_API_URL = "http://localhost:8080/auth/login"

# Initialize session state variables
if "authenticated" not in st.session_state:
    st.session_state["authenticated"] = False
    st.session_state["user_id"] = None
    st.session_state["role"] = None

# Function to handle login
def login_page():
    st.title("🎬 Movie Tracker - Login")

    username = st.text_input("Username")
    st.session_state["username"] = username
    password = st.text_input("Password", type="password")

    if st.button("Login"):
        response = requests.post(f"{LOGIN_API_URL}?username={username}&password={password}")
        data = response.json()
        st.session_state["user_id"] = data.get("userId")
        st.session_state["role"] = data.get("role")

        if response.status_code == 200:
            st.session_state["authenticated"] = True
            
            st.success("✅ Login Successful!")
            st.rerun()  # Reload the app to show main page
        else:
            st.error("❌ Invalid credentials. Please try again.")

# Function to handle main app UI
def main_app():
    st.title("🎬 Movie Tracker - Home")

    st.write(f"Welcome, **User {st.session_state['user_id']}**!")
    st.write(f"Your role: **{st.session_state['role']}**")

    # Add your movie search, favorites, and watchlist features here
    if st.button("Logout"):
        st.session_state["authenticated"] = False
        st.rerun()  # Reload app and show login page

# Conditionally display the login page or main app
if not st.session_state["authenticated"]:
    login_page()
else:
    app_main.main()  # Run the main app from app_main.py
