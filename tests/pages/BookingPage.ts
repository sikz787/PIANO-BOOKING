// Location: tests/pages/BookingPage.ts

import { Page, Locator } from '@playwright/test';

export class BookingPage {
    readonly page: Page;
    readonly nameInput: Locator;
    readonly emailInput: Locator;
    readonly submitBtn: Locator;

    constructor(page: Page) {
        this.page = page;
        
        // FIX: Use 'getByPlaceholder' or 'getByLabel' as seen in your snapshot
        this.nameInput = page.getByPlaceholder('Enter name');
        this.emailInput = page.getByPlaceholder('email@example.com');
        
        // FIX: Use 'getByRole' for the button labeled "REGISTER NOW"
        this.submitBtn = page.getByRole('button', { name: 'REGISTER NOW' });
    }

    async navigate() {
        await this.page.goto('/'); 
    }

    async bookLesson(name: string, email: string) {
        // These will now find the elements correctly!
        await this.nameInput.fill(name);
        await this.emailInput.fill(email);
        await this.submitBtn.click();
    }
}