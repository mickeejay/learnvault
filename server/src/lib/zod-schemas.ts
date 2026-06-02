import { z } from "zod"

export const courseIdParamSchema = z.object({
	courseId: z
		.string({ message: "Course ID is required" })
		.cuid({ message: "Invalid course ID format" }),
})

export const coursesQuerySchema = z.object({
	limit: z
		.string()
		.optional()
		.transform((v) => (v !== undefined ? parseInt(v, 10) : 20))
		.pipe(z.number().int().min(1).max(100)),
	cursor: z.string().optional(),
})

export const verifyBodySchema = z.object({
	walletAddress: z.string().min(1),
	signature: z.string().min(1),
})

export const postCommentBodySchema = z.object({
	proposalId: z.string().min(1),
	content: z.string().min(1),
	parentId: z.string().optional(),
})

export const voteCommentBodySchema = z.object({
	type: z.enum(["upvote", "downvote"]),
})

export const submitMilestoneBodySchema = z
	.object({
		scholarAddress: z.string().min(1),
		courseId: z.string().min(1),
		milestoneId: z.number().int().nonnegative(),
		evidenceGithub: z.string().url().optional(),
		evidenceIpfsCid: z.string().optional(),
		evidenceDescription: z.string().optional(),
	})
	.refine(
		(d) =>
			d.evidenceGithub !== undefined ||
			d.evidenceIpfsCid !== undefined ||
			d.evidenceDescription !== undefined,
		{
			message: "At least one evidence field is required",
			path: ["evidenceDescription"],
		},
	)

export const rejectMilestoneBodySchema = z.object({
	reason: z.string().min(1),
})

export const validateMilestoneSchema = z.object({
	courseId: z.string().cuid({ message: "Invalid course ID format" }),
	learnerAddress: z.string().min(1),
	milestoneId: z.number().int().nonnegative(),
})
