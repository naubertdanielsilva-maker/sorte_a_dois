const API = {
    async request(url, options = {}) {
        const token = localStorage.getItem("accessToken");

        const headers = {
            "Content-Type": "application/json",
            ...(options.headers || {})
        };

        if (token) {
            headers["Authorization"] = `Bearer ${token}`;
        }

        try {
            const response = await fetch(url, {
                ...options,
                headers
            });

            const data = await response.json().catch(() => null);

            if (!response.ok) {
                throw {
                    status: response.status,
                    message: data?.detail || "Erro ao executar a operação.",
                    data
                };
            }

            return data;
        } catch (error) {
            console.error("Erro API:", error);
            throw error;
        }
    },

    get(url) {
        return this.request(url);
    },

    post(url, body = {}) {
        return this.request(url, {
            method: "POST",
            body: JSON.stringify(body)
        });
    },

    patch(url, body = {}) {
        return this.request(url, {
            method: "PATCH",
            body: JSON.stringify(body)
        });
    },

    delete(url) {
        return this.request(url, {
            method: "DELETE"
        });
    },

    upload(url, formData) {
        const token = localStorage.getItem("accessToken");

        const headers = {};

        if (token) {
            headers["Authorization"] = `Bearer ${token}`;
        }

        return fetch(url, {
            method: "POST",
            headers,
            body: formData
        }).then(async response => {
            const data = await response.json().catch(() => null);

            if (!response.ok) {
                throw {
                    status: response.status,
                    message: data?.detail || "Erro no upload.",
                    data
                };
            }

            return data;
        });
    }
};