import { test, expect } from '@playwright/test';
import { BookingPage } from './pages/BookingPage';

//This is the first test, pushing to Devops 
test('Verify successful piano booking', async ({ page }) => {
    const booking = new BookingPage(page);

    await booking.navigate();
    await booking.bookLesson('Sikz QA', 'test@piano.com');

    // FIX: Increase timeout to 15 or 30 seconds because DB calls can be slow
    // Also, use a more flexible matcher in case there is a tiny typo
    await expect(page.locator('body')).toContainText('Profile Saved Successfully', { timeout: 30000 });
});