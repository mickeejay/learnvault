import { Router } from "express"

import { createAuthControllers } from "../controllers/auth.controller"
import { nonceRateLimiter } from "../middleware/nonce-rate-limit.middleware"
import { validate } from "../middleware/validate"
import * as schemas from "../lib/zod-schemas"
import { type AuthService } from "../services/auth.service"

export function createAuthRouter(authService: AuthService): Router {
	const router = Router()
	const { getNonce, postVerify } = createAuthControllers(authService)

	router.get("/nonce", nonceRateLimiter, (req, res) => {
		void getNonce(req, res)
	})

	router.post(
		"/verify",
		validate({ body: schemas.verifyBodySchema }),
		(req, res) => {
			void postVerify(req, res)
		},
	)

	return router
}
