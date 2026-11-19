<script setup lang="ts">
import { formatCurrency } from '@/lib/utils';

interface PaymentMethod {
    id: string;
    name: string;
    fee: number;
    percent?: number;
    action: 'add' | 'multiply';
    img: string;
}

defineProps<{
    selectedPayment: string | null;
    paymentMethods: PaymentMethod[];
}>();

const emit = defineEmits<{
    'update:selectedPayment': [value: string | null];
}>();

const feeLabel = (method: PaymentMethod) => {
    const percent = method.percent
        ? `${(method.percent * 100).toFixed(1).replace(/\.0$/, '')}%`
        : '';

    if (method.action === 'multiply') {
        return `${(method.fee * 100).toFixed(1)}%`;
    }

    if (method.fee > 0 && percent) {
        return `${formatCurrency(method.fee)} + ${percent}`;
    }

    if (method.fee > 0) {
        return formatCurrency(method.fee);
    }

    return percent || formatCurrency(method.fee);
};
</script>

<template>
    <section class="rounded-lg border border-border/50 bg-card p-6 shadow-sm">
        <h2
            class="mb-4 flex items-center gap-2 text-lg font-bold text-foreground"
        >
            <span
                class="flex h-7 w-7 items-center justify-center rounded-full bg-primary text-sm font-bold text-primary-foreground"
                >4</span
            >
            Pilih Metode Pembayaran
        </h2>

        <div class="space-y-2">
            <button
                v-for="method in paymentMethods"
                :key="method.id"
                class="flex w-full items-center gap-4 rounded-lg border-2 p-4 transition-all"
                :class="
                    selectedPayment === method.id
                        ? 'border-primary bg-primary/5'
                        : 'border-border/50 hover:border-primary/50'
                "
                @click="emit('update:selectedPayment', method.id)"
            >
                <img
                    :src="method.img"
                    :alt="method.name"
                    class="h-8 w-12 object-contain"
                    loading="lazy"
                />
                <span class="flex-1 text-left font-medium text-foreground">
                    {{ method.name }}
                </span>
                <span class="text-sm text-muted-foreground">
                    Fee: {{ feeLabel(method) }}
                </span>
            </button>
        </div>
    </section>
</template>
