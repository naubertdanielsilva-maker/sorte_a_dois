const ADMIN_EMAIL = "naubertdaniel.silva@gmail.com";

let loggedUser = null;

function getToken() {
    return localStorage.getItem("accessToken");
}

function getLoggedUser() {
    const savedUser = localStorage.getItem("loggedUser");

    if (!savedUser) return null;

    return JSON.parse(savedUser);
}

function isLoggedIn() {
    return !!getToken() && !!getLoggedUser();
}

function isAdmin() {
    const user = getLoggedUser();
    return user && user.email.toLowerCase() === ADMIN_EMAIL.toLowerCase();
}

async function login() {
    try {
        const data = await API.post("/auth/login", {
            email: document.getElementById("loginEmail").value,
            password: document.getElementById("loginPassword").value
        });

        localStorage.setItem("accessToken", data.access_token);
        localStorage.setItem("loggedUser", JSON.stringify(data.user));

        loggedUser = data.user;

        showToast(`Bem-vindo(a), ${data.user.name}!`);
        updateAdminVisibility();
        showScreen("screen-home");
        await loadAppData();

    } catch (error) {
        showToast(error.message || "Erro ao fazer login.", "error");
    }
}

function logout() {
    localStorage.removeItem("accessToken");
    localStorage.removeItem("loggedUser");

    loggedUser = null;

    updateAdminVisibility();
    showScreen("screen-login");
}

function updateAdminVisibility() {
    const adminButton = document.getElementById("adminNavButton");

    if (!adminButton) return;

    if (isAdmin()) {
        adminButton.classList.remove("hidden");
    } else {
        adminButton.classList.add("hidden");
    }
}

function openAdminScreen() {
    if (!isAdmin()) {
        showToast("A tela de ajustes é restrita ao Naubert.", "error");
        showScreen("screen-home");
        return;
    }

    showScreen("screen-admin");
}