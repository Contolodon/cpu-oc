	/* ============================================================ */
	/* REAL HARDWARE OVERCLOCK                                     */
	/* Modify existing max LUT entry (safer than adding new slot)  */
	/* Little (cpu 0-3): 2100 MHz    Big (cpu 4-7): 2700 MHz      */
	/* Uses existing LUT slot + stock voltage = no overvolt risk  */
	/* ============================================================ */
	{
		u32 oc_lval, oc_freq_khz, oc_data, last_idx;
		unsigned long oc_freq_hz;

		last_idx = (i > 0) ? (i - 1) : 0;

		if (cpumask_first(&c->related_cpus) < 4)
			oc_freq_khz = 2100000;
		else
			oc_freq_khz = 2700000;

		if (xo_rate == 0) {
			pr_err("qcom-cpufreq-hw: xo_rate=0, skip OC\n");
			goto oc_done;
		}

		oc_lval = (oc_freq_khz * 1000) / xo_rate;

		/* Modify existing max LUT entry - keep same voltage */
		oc_data = readl_relaxed(c->base + offsets[REG_FREQ_LUT] +
					last_idx * lut_row_size);
		oc_data = (oc_data & ~LUT_L_VAL) | (oc_lval & LUT_L_VAL);
		writel_relaxed(oc_data, c->base + offsets[REG_FREQ_LUT] +
			       last_idx * lut_row_size);

		/* Read back to verify hardware accepted the write */
		oc_data = readl_relaxed(c->base + offsets[REG_FREQ_LUT] +
					last_idx * lut_row_size);
		oc_freq_hz = (FIELD_GET(LUT_SRC, oc_data)) ?
			     (xo_rate * FIELD_GET(LUT_L_VAL, oc_data) / 1000) :
			     (cpu_hw_rate / 1000);

		if (oc_freq_hz == oc_freq_khz)
			pr_info("qcom-cpufreq-hw: HW OC OK cpu%d -> %lu kHz (L_VAL=%u)\n",
				cpumask_first(&c->related_cpus), oc_freq_hz, oc_lval);
		else
			pr_warn("qcom-cpufreq-hw: HW OC MISMATCH cpu%d -> wrote %u read %lu (LUT read-only?)\n",
				cpumask_first(&c->related_cpus), oc_freq_khz, oc_freq_hz);

		/* Update software table to reflect new frequency */
		c->table[last_idx].frequency = oc_freq_hz;
	}

oc_done:
